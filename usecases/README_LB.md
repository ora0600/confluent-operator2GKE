
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

Please replace `${PROVIDER}` with gcp or aws, depends on which cloud provider you work currently.
```bash
# Set the env for google GKE
export PROVIDER=gcp
# Set the env for aws EKS
export PROVIDER=aws
```

### Create LoadBalancer for KSQL
```bash
cd infrastructure/terraform/${PROVIDER}/confluent-operator/helm/
# or cd infrastructure/terraform/aws/confluent-operator/helm/
echo "Create LB for KSQL"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set ksql.enabled=true \
 --set ksql.loadBalancer.enabled=true \
 --set ksql.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud ksql \
 ./confluent-operator
 kubectl rollout status sts -n operator ksql
```
### Create LoadBalancer for Schema Registry
```BASH
echo "Create LB for Schemaregistry"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set schemaregistry.enabled=true \
 --set schemaregistry.loadBalancer.enabled=true \
 --set schemaregistry.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud schemaregistry \
 ./confluent-operator
 kubectl rollout status sts -n operator schemaregistry
```
### Create LoadBalancer for Control Center
```BASH
echo "Create LB for Control Center"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set controlcenter.enabled=true \
 --set controlcenter.loadBalancer.enabled=true \
 --set controlcenter.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud controlcenter \
 ./confluent-operator
 kubectl rollout status sts -n operator controlcenter
```

### (Optional) Create LoadBalancer for Kafka
```BASH
echo "Create LB for Kafka"
helm upgrade -f ./providers/${PROVIDER}.yaml \
 --set kafka.enabled=true \
 --set kafka.loadBalancer.enabled=true \
 --set kafka.loadBalancer.domain=mydevplatform.${PROVIDER}.cloud kafka \
 ./confluent-operator
 kubectl rollout status sts -n operator kafka
```

### Check Loadbalancers und setup local hosts
Loadbalancers are created please wait a couple of minutes...and check
```BASH
kubectl get services -n operator | grep LoadBalancer
```
Because we do not want to buy a domain `mydevplatform.provider.cloud`, we have to add the IPs into our `/etc/hosts` file, so that we can reach the components. 

First get the external IP adresses of the load balancer:

```bash
kubectl get services -n operator | grep LoadBalancer
```

Then edit the `/etc/hosts` file and add the new IPs with hostnames:
For aws you won#t get the Public IP Adresss please ping the external hosts e.g.
```bash
ping a7dd71d73184111eaab430a8209a4a74-1231623882.eu-central-1.elb.amazonaws.com
...
```
and then change your `/etc/hosts`

```bash
sudo vi /etc/hosts
# Add your IPs and the domain names
EXTERNALIP-OF-KSQL    ksql.mydevplatform.${PROVIDER}.cloud ksql-bootstrap-lb ksql
EXTERNALIP-OF-SR      schemaregistry.mydevplatform.${PROVIDER}.cloud schemaregistry-bootstrap-lb schemaregistry
EXTERNALIP-OF-C3      controlcenter.mydevplatform.${PROVIDER}.cloud controlcenter controlcenter-bootstrap-lb

# For example, add the line:
# 34.77.51.245 controlcenter.mydevplatform.gcp.cloud controlcenter controlcenter-bootstrap-lb
...
```

Now you access the Confluent Control Center externally. Open your Brower and copy the URL: [http://controlcenter:9021/](http://controlcenter:9021/) and enter User=admin and password=Developer1. 
You can the following in your Control Center
* open Topic Viewer and check messages of Topic example
* open KSQL Editor: Create a Stream on topic example: 
  ```
  create STREAM EXAMPLE_S (field_0 VARCHAR) WITH (KAFKA_TOPIC='example', VALUE_FORMAT='DELIMITED');
  # set auto.offset.reset=Earliest
  select * from EXAMPLE_S;
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

You can do this for each Confluent component, create one port-fowarding, e.g. Control Center:

```bash
# Port Forward Control Center
kubectl port-forward controlcenter-0 -n operator 7000:9021
```

Now, you can open your brower and run the control center locally on Port 7000 [Control Center](http://localhost:7000)). Please enter Username=admin and Password=Developer1

If you want to forward multiple ports locally then use better an utility. E.g. kubefwd;

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