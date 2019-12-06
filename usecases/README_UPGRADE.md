# Doing a version Upgrade from 5.3.1 to 5.3.0 

In this short demo we do a downgrade of control center from 5.3.1.0 to 5.3.0.0.
Further information see [Confluent docu](https://docs.confluent.io/current/installation/operator/co-management.html)

## For AWS
```bash
terraform/aws/confluent-operator/helm
helm upgrade \
-f ./providers/aws.yaml \
--set controlcenter.enabled=true \
--set controlcenter.image.tag=5.4.0 controlcenter \
./confluent-operator
```

## For GCP
```bash
cd terraform/gcp/confluent-operator/helm
helm upgrade \
-f ./providers/gcp.yaml \
--set controlcenter.enabled=true \
--set controlcenter.image.tag=5.3.0.0 controlcenter \
./confluent-operator
```

# Check Upgrade of Control Center to 5.3.0

A new container will be pulled and control center will be started with new version. You will see this best with 
```bash
kubectl get events --sort-by=.metadata.creationTimestamp -n operator
```
Additional commands to debug your environment.
```bash
kubectl get pods -n operator
kubectl get services -n operator | grep LoadBalancer
kubectl -n operator get all
kubectl logs controlcenter-0 -n operator
```
Use your browser to check the new control center [Control Center](http://controlcenter:9021/settings/processing) under Hambuerg menu and then status settings, you will see the new version of 5.3.0 (after refreshing the cache of your brower).
