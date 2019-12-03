#!/usr/bin/env bash

echo "Removing dashboard"
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml


helm delete --no-hooks --purge prom &
helm delete --no-hooks --purge metrics &

../../02_deleteConfluentPlatform.sh || true


echo "Purging namespaces..."
kubectl delete --grace-period=0 --force --all sts --namespace=operator || true

kubectl delete --grace-period=0 --force --all deployment --namespace=operator || true

kubectl delete --grace-period=0 --force --all service --namespace=operator || true

kubectl delete --grace-period=0 --force --all pods --namespace=operator || true
