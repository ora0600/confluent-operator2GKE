# Doing a version Upgrade from 6.0.0 to 5.5.1 

In this short demo we do a downgrade of control center from 5.3.1.0 to 5.3.0.0.
Further information see [Confluent docu](https://docs.confluent.io/current/installation/operator/co-management.html)

## For AWS
```bash
cd terraform/aws/confluent-operator/helm
helm upgrade --install \
controlcenter \
./confluent-operator  -f ../../aws.yaml \
--namespace operator \
--set controlcenter.enabled=true \
--set controlcenter.image.tag=5.5.1.0
```

## For GCP
```bash
cd terraform/gcp/confluent-operator/helm
helm upgrade --install \
controlcenter \
./confluent-operator  -f ../../gcp.yaml \
--namespace operator \
--set controlcenter.enabled=true \
--set controlcenter.image.tag=5.5.1.0
```

# Check Upgrade of Control Center to 5.5.1

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
Use your browser to check the new control center [Control Center](http://controlcenter:9021/settings/processing) under Hambuerg menu and then status settings, you will see the new version of 5.5.1 (after refreshing the cache of your brower).

ATTENTION:
If you run on AWS, please check the IP of the Loadbalancer again. I may possible that has changed and you can not access control-center with the old IP in your /etc/hosts for Control Center.
