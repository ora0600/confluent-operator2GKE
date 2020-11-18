#!/usr/bin/env bash

set -o xtrace
export PROJECT_ID=$1
export REGION=$2
export CLUSTER=$3
export PROVIDER=$4

if [ "$PROVIDER" == "gcp" ]; then
 echo "delete gcp cluster"
 gcloud container --project ${PROJECT_ID} clusters --region "${REGION}"
 gcloud container --project ${PROJECT_ID} clusters delete "${CLUSTER}" --region "${REGION}" --async --quiet
 yes Y | gcloud compute disks list | grep cp60-cluster | awk '{printf "gcloud compute disks delete %s --zone %s; ", $1, $2}' | bash
fi

# need eksctl 0.31 or later, but terraform will destroy without this feature
if [ "$PROVIDER" == "aws" ]; then
 echo "delete aws cluster"
 aws eks list-nodegroups --cluster-name ${CLUSTER}
 aws eks delete-nodegroup --nodegroup-name cp60 --cluster-name ${CLUSTER}
 aws eks delete-cluster --name ${CLUSTER}

fi

if [ "$PROVIDER" == "aws" ]; then
echo "delete azure cluster"
fi
