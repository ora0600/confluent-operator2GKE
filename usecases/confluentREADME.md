# Check Confluent Cluster

If you did run already `terraform apply` in [terraform/aws](terraform/aws) or [terraform/gcp](terraform/gcp) then you deployed the following objects:
* K8s dashboard 
 See above how to start k8s dashboard, you need a token to access
 1. use for gcp `gcloud config config-helper --format=json | jq -r '.credential.access_token'` for login
 2. use for aws `kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')`
* Confluent Operator
* Confluent Cluster running in Multi-Zone with with replica of 3 for Zookeeper and Kafka Broker

It will also set your kubectl context to the k8s cluster automatically. (To undo this, see `kubectl config get-contexts` and switch to your preferred context)

## Quick Start

Ensure your k8s cluster is running:
  * GCP
```bash
gcloud container clusters list
```
  * AWS
```bash
eksctl get cluster 
```

The following setup was provisioned:
![k8s cluster deployed pods](../images/k8s_cluster.png)

## test confluent platform on k8s
First which namespaces are setup:
```bash
kubectl get namespace
```

After the script execution please check again if Confluent Platform cluster is running:
```bash
kubectl get pods -n operator
# Output should look like this
NAME                          READY   STATUS    RESTARTS   AGE
cc-manager-5c8894687d-j6lms   1/1     Running   1          11m
cc-operator-9648c4f8d-w48v8   1/1     Running   0          11m
controlcenter-0               1/1     Running   0          3m10s
kafka-0                       1/1     Running   0          8m53s
kafka-1                       1/1     Running   0          7m31s
kafka-2                       1/1     Running   0          6m6s
ksql-0                        1/1     Running   0          6m
schemaregistry-0              1/1     Running   1          6m53s
zookeeper-0                   1/1     Running   0          10m
zookeeper-1                   1/1     Running   0          10m
zookeeper-2                   1/1     Running   0          10m
```
Check the services
```bash
kubectl get services -n operator
```
Check the nodes of k8s cluster
```bash
# get  Nodes
kubectl get node
```
Check events happening during deployment:
```bash
# List Events sorted by timestamp
kubectl get events --sort-by=.metadata.creationTimestamp -n operator
kubectl get events -n operator
```

## K8s Dashboard

* Run `kubectl proxy &`
* Go to [K8s dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)
* Login to K8s dashboard using The token from GCP: `gcloud config config-helper --format=json | jq -r '.credential.access_token'` or AWS: `kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')`

The k8s Dashboard will show for namespace operator the following :
![k8s cluster Dashboard](../images/k8s_dsahboard.png)
k8s_dsahboard.png

## Access the Pods directly

Access the pod into broker kafka-0:

```bash
kubectl -n operator exec -it kafka-0 bash
```

All Kafka brokers should have a config file like the following:

```bash
cat kafka.properties
bootstrap.servers=kafka:9071
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
sasl.mechanism=PLAIN
security.protocol=SASL_PLAINTEXT
```

Query the bootstrap server:

```bash
kafka-broker-api-versions --command-config kafka.properties --bootstrap-server kafka:9071
```

Create topic and fill with some data;
```bash
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--create --replication-factor 3 \
--partitions 6 --topic example
# list topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--list
# produce data
seq 10000 | kafka-console-producer --topic example --broker-list kafka:9071 --producer.config kafka.properties
# Describe topic example
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
```
The topic example is very good shared among the brokers:
```
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,2,0 Isr: 1,2,0
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,1,2 Isr: 0,1,2
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,0,2 Isr: 1,0,2
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,1,0 Isr: 2,1,0
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
```


### Test KSQL (Data Analysis and Processing)

Go into the KSQL Server and play around with KSQL CLI:

```bash
kubectl -n operator exec -it ksql-0 bash
$ ksql
ksql> list topics;
ksql> PRINT 'example' FROM BEGINNING;
ksql> list streams;
ksql> list tables;
ksql> 
```
The script already creates some KSQL Streams and Tables (JSON-to-AVRO Conversion; and a few SELECT Queries). Take a look at these queries or write your own from KSQL CLI or Confluent Control Center.

## External Access to your Confluent Plaform

### Test Control Center (Monitoring) with external access

Use your browser and go to [http://controlcenter:9021](http://controlcenter:9021) enter the Username=admin and Password=Developer1.

This will not work, because no external access was setup.

Please follow the use case for Loadbalancers in this project [README_LB.md](README_LB.md)

HINT: Please follow the Confluent documentation [External Access](https://docs.confluent.io/current/installation/operator/co-endpoints.html#co-loadbalancer-kafka). 


## Confluent Platform on Kubernetes

For more details, follow the examples of how to use and play with Confluent Platform on GCP K8s on [Confluent docs](https://docs.confluent.io/current/installation/operator/co-deployment.html)

