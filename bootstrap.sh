#!/usr/bin/env bash

if ! command -v helm &> /dev/null
then
    echo "helm could not be found, installing"
	# curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
	chmod 700 get_helm.sh
	sudo ./get_helm.sh
	rm ./get_helm.sh
fi

echo
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
cat << EOF Cluster app details:

ArgoCD login:
	user: admin 
	password: $(kubectl get pods --selector app.kubernetes.io/name=argocd-server --output name --namespace argocd | cut -d'/' -f 2)
EOF
# Dashboard login token: 
# 	$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
# EOF