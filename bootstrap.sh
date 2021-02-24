#!/usr/bin/env bash

if ! command -v k3d &> /dev/null
then
    echo "k3d could not be found, installing"
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
	command -v k3d &> /dev/null || echo "Unable to find or install helm" & exit 1
fi

if ! command -v helm &> /dev/null
then
    echo "helm could not be found, installing"
	# curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
	chmod 700 get_helm.sh
	sudo ./get_helm.sh
	rm ./get_helm.sh
fi

if ! docker -v &> /dev/null
then
	echo "Unable to connect to docker daemon"
	exit 1
fi

echo
echo "Deleting cluster"
k3d cluster delete

echo
echo "Creating local cluster"
k3d cluster create --api-port 6550 -p "8081:80@loadbalancer" --agents 1

echo
kubectl config use-context k3d-k3s-default
kubectl cluster-info

echo
# helm dep update charts/argo-cd/
# Initial deploy
echo "Performing initial argocd deploy"
helm install argo-cd charts/argo-cd/ --namespace argocd --create-namespace --wait --timeout 10m --dependency-update
# Wait for pods to be ready

echo
echo "Waiting for pods..."
kubectl wait --for=condition=ready pods -l app.kubernetes.io/part-of=argocd -n argocd --timeout 5m 

# Apply apps 
helm template apps/ | kubectl apply -f -

# Start port forwarding argo UI
# kubectl port-forward svc/argo-cd-argocd-server 8080:443 -n argocd


echo
cat << EOF > Cluster app details:

ArgoCD login:
	user: admin 
	password: $(kubectl get pods --selector app.kubernetes.io/name=argocd-server --output name --namespace argocd | cut -d'/' -f 2)

Dashboard login token: 
	$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
EOF