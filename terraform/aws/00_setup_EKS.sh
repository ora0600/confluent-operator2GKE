#!/usr/bin/env bash

set -e
REGION=${1}
CLUSTER=${2}

# update kubeconfig with AWS cluster information
# 
aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER}

echo "Provisioning K8s cluster..."
eksctl get cluster

# _idempotent_ setup

until kubectl cluster-info >/dev/null 2>&1; do
    echo "kubeapi not available yet..."
    sleep 3
done

# Create admin-user service account
kubectl apply -f k8s-admin-service-account.yaml

echo " EKS cluster created"
eksctl get cluster