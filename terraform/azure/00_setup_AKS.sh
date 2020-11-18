#!/usr/bin/env bash

set -e
REGION=${1}
CLUSTER=${2}
RESOURCEGROUP=${3}

# update kubeconfig with Azure cluster information
echo "Let's make cluster awar to kubectl"
az aks get-credentials --name ${CLUSTER} --resource-group ${RESOURCEGROUP} --overwrite-existing
export KUBECONFIG=~/.kube/config

echo "Provisioning K8s cluster..."
kubectl cluster-info
kubectl get nodes

# Create service account
kubectl apply -f k8s-admin-service-account.yaml

# _idempotent_ setup

until kubectl cluster-info >/dev/null 2>&1; do
    echo "kubeapi not available yet..."
    sleep 3
done

# Create admin-user service account
#kubectl apply -f k8s-admin-service-account.yaml

echo " AKS cluster created"
az aks show -n ${CLUSTER} -g ${RESOURCEGROUP}

