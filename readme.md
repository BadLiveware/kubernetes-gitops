# Source 
https://www.arthurkoziel.com/setting-up-argocd-with-helm/

# Resource structure
The repository is (funtionally) divided into two directories, `apps/` and `charts/`.

## `apps/`
This is the dir that contains the root application that ArgoCD looks at to manage (part of) the cluster
## `charts/`
This dir contains custom helm charts that is used by the applications in `apps/`

## Logical structure
There is a manifest(`apps/templates/root`) in apps/ that is the root application that ArgoCD manages, this application in turn references all others that are defined in this repository
```yaml
# apps/templates/root.yaml
# Trimmed for clarity

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root # Name of the application
spec:

  source:
    path: apps/ # Root of the chart to deploy
    repoURL: https://github.com/BadLiveware/kubernetes-gitops.git
    targetRevision: HEAD # Which revision to follow, can be a ref, commit, tag or branch

  destination:
    server: https://kubernetes.default.svc # The cluster to deploy to, this can be the cluster in which argo runs or an external
    namespace: argocd # The namespace to deploy the application(chart) to
```

### Dependency graph

![directory structure](https://raw.githubusercontent.com/BadLiveware/kubernetes-gitops/master/docs/assets/repo_structure.svg "Repo structure")

# Normal operation
## Flow
![normal workflow](https://raw.githubusercontent.com/BadLiveware/kubernetes-gitops/master/docs/assets/normal_operation.svg "Normal operation")

Argo will read the configured git repo to find the desired state of manifests, it will then sync the cluster so that it conforms with the repo definition

# Bootstrapping
## Flow
![bootstrapping workflow](https://raw.githubusercontent.com/BadLiveware/kubernetes-gitops/master/docs/assets/bootstrapping.svg "Bootstrapping")

While bootstrapping we have to imperatively(`kubectl apply`) configure the cluster to install argo-cd, after ArgoCD will sync its own state

### ./bootstrap.sh
This script performs the initial bootstrap of argocd

#### Generate chart lock
```console
$ helm repo add argo-cd https://argoproj.github.io/argo-helm
$ helm dep update charts/argo-cd/
$ echo "charts/" > charts/argo-cd/.gitignore
```

#### Initial argocd install
```console
$ helm install argo-cd charts/argo-cd/ --namespace argocd --create-namespace
```

#### Setup app of apps to manage the entire repository
```console
$ helm template apps/ | kubectl apply -f -
```

