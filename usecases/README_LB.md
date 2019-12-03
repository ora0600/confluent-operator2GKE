
# External Access to the Confluent Platform Running in K8s

  Two possibilities to configure external access from outside the Kubernetes cluster (e.g. from your laptop):

  1. Create external loadbalancers
  2. Do port forwarding to your local machine

The `terraform apply` created a Confluent Cluster without Loadbalancers. So have no external access to your Confluent Cluster.

## 1. External Loadblancer

The first possibiliy is to create for each Confluent Component an external Loadbalancer in k8s.

For this we can use the Confluent Operator and tell k8s to add a loadbalancer.

Please, go first in the right directory for
  * AWS `cd terraform/aws`
  * GCP `cd terraform/gcp`

### Create LoadBalancer for KSQL
```bash
cd infrastructure/terraform/gcp/confluent-operator/helm/
# or cd infrastructure/terraform/aws/confluent-operator/helm/
echo "Create LB for KSQL"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set ksql.enabled=true \
 --set ksql.loadBalancer.enabled=true \
 --set ksql.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud ksql \
 ./confluent-operator
 kubectl rollout status sts -n operator ksql
```
### Create LoadBalancer for Kafka
```
echo "Create LB for Kafka"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set kafka.enabled=true \
 --set kafka.loadBalancer.enabled=true \
 --set kafka.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud kafka \
 ./confluent-operator
 kubectl rollout status sts -n operator kafka
```
### Create LoadBalancer for Schema Registry
```
echo "Create LB for Schemaregistry"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set schemaregistry.enabled=true \
 --set schemaregistry.loadBalancer.enabled=true \
 --set schemaregistry.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud schemaregistry \
 ./confluent-operator
 kubectl rollout status sts -n operator schemaregistry
```
### Create LoadBalancer for Control Center
```
echo "Create LB for Control Center"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set controlcenter.enabled=true \
 --set controlcenter.loadBalancer.enabled=true \
 --set controlcenter.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud controlcenter \
 ./confluent-operator
kubectl rollout status sts -n operator controlcenter
```
### Check Loadbalancers und setup local hosts
Loadbalancers are created please wait a couple of minutes...and check
```
kubectl get services -n operator | grep LoadBalancer
```
Because we do not want to buy a domain `mydevplatform.provider.cloud`, we have to add the IPs into our `/etc/hosts` file, so that we can reach the components. 

First get the external IP adresses of the load balancer:

```bash
kubectl get services -n operator | grep LoadBalancer
```

Then edit the `/etc/hosts` file and add the new IPs with hostnames:

```bash
sudo vi /etc/hosts
# Add your IPs and the domain names
EXTERNALIP-OF-KSQL    ksql.mydevplatform.gcp.cloud ksql-bootstrap-lb ksql
EXTERNALIP-OF-SR      schemaregistry.mydevplatform.gcp.cloud schemaregistry-bootstrap-lb schemaregistry
EXTERNALIP-OF-C3      controlcenter.mydevplatform.gcp.cloud controlcenter controlcenter-bootstrap-lb
EXTERNALIP-OF-KB0     b0.mydevplatform.gcp.cloud kafka-0-lb kafka-0 b0
EXTERNALIP-OF-KB1     b1.mydevplatform.gcp.cloud kafka-1-lb kafka-1 b1
EXTERNALIP-OF-KB2     b2.mydevplatform.gcp.cloud kafka-2-lb kafka-2 b2
EXTERNALIP-OF-KB      kafka.mydevplatform.gcp.cloud kafka-bootstrap-lb kafka

# For example, add the line:
# 34.77.51.245 controlcenter.mydevplatform.gcp.cloud controlcenter controlcenter-bootstrap-lb
```

## 2. Port Forwarding

First check which ports your Confluent components listen to:

```bash
# control center
kubectl get pods controlcenter-0 -n operator --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
# ksql
kubectl get pods ksql-0 -n operator --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
# Schema Registry
kubectl get pods schema-registry-0 -n operator --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
# Kafka
kubectl get pods kafka-0 -n operator --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}'
```

You can do for each Confluent component create one port-fowarding, e.g. Control Center:

```bash
# Port Forward Control Center
kubectl port-forward controlcenter-0 -n operator 7000:9021
```

Now, you can open your brower and run the control center locally on Port 7000 [Control Center](http://localhost:7000)). Please enter Username=admin and Password=Developer1

If you want to forward multiple ports locally then use an utility. E.g. kubefwd;

```bash
# make sure context is set
kubectl config current-context
# install kubefwd on macos
brew install txn2/tap/kubefwd
brew upgrade kubefwd
# foward all services for -n operator
sudo kubefwd svc -n operator
```

kubefwd is generating for all k8s services an Port forwarding and add in /etc/hosts the correct hostname.