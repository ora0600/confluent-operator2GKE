#!/usr/bin/env bash

set -e

CNAME=${1}
REGION=${2}
PROJECT=${3}

echo "Provisioning K8s cluster..."
gcloud container clusters get-credentials ${CNAME} --region ${REGION}

# Create admin-user service account
kubectl apply -f k8s-admin-service-account.yaml
echo "If you got an wrong namespace error here: please use namespace kube-system"


# Context should be set automatically
#kubectl use-context gke_${3}_${2}_${1}

echo " GKE cluster created"
