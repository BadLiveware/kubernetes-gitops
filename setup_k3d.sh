#!/usr/bin/env bash

if ! command -v k3d &> /dev/null
then
	echo "k3d could not be found, installing"
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
	command -v k3d &> /dev/null || echo "Unable to find or install helm" & exit 1
  echo 
fi

if ! docker -v &> /dev/null
then
  echo "Unable to connect to docker daemon"
  exit 1
fi

echo "Deleting cluster"
k3d cluster delete

echo
echo "Creating local cluster"
k3d cluster create --api-port 6550 -p "8080:80@loadbalancer" -p "8081:443@loadbalancer" --agents 1

echo
kubectl config use-context k3d-k3s-default