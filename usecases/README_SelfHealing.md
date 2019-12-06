# Self-Healing of K8s and Kafka Cluster
Now we try to kill one kafka broker pod and see what is happining

## Do kill Kafka Broker Pod
First check if cluster is running
```bash
kubectl get pods -n operator
```
Before killing we will check the partitions on brokers
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,0,2 Isr: 1,0,2
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,1,0
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,2,0 Isr: 1,2,0
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 0,1,2
```

Now, killing a broker
```bash
kubectl delete pods kafka-1 -n operator
kubectl get events --sort-by=.metadata.creationTimestamp -n operator
kubectl get pods -n operator
# Cluster is restarting
kafka-0                       1/1     Running    0          57m
kafka-1                       0/1     Init:0/1   0          5s
kafka-2                       1/1     Running    0          55m
# Check again
kafka-0                       1/1     Running   0          58m
kafka-1                       0/1     Running   0          24s
kafka-2                       1/1     Running   0          55m
# Broker is up and running
kafka-0                       1/1     Running   0          58m
kafka-1                       1/1     Running   0          53s
kafka-2                       1/1     Running   0          56m
```
After  killing we will check the partitions on brokers again
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output Broker 1 is missing
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 0       Replicas: 1,0,2 Isr: 0,2,1
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,0,1
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
        Topic: example  Partition: 3    Leader: 2       Replicas: 1,2,0 Isr: 2,0,1
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 0,2,1
```
In that case we have to rebalance the brokers again:
```bash
kubectl -n operator exec -it kafka-0 bash
# create a config file
cat << EOF > config.properties
confluent.license=
confluent.rebalancer.metrics.sasl.mechanism=PLAIN
confluent.rebalancer.metrics.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
confluent.rebalancer.metrics.bootstrap.servers=kafka:9071
confluent.rebalancer.metrics.security.protocol=SASL_PLAINTEXT
EOF
# start the rebalancer
confluent-rebalancer execute --zookeeper zookeeper:2181/kafka-operator --metrics-bootstrap-server kafka:9071 --throttle 10000000 --verbose --config-file config.properties 
# check the status 
confluent-rebalancer status --zookeeper zookeeper:2181/kafka-operator
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output Broker are balanced
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,0,2 Isr: 0,2,1
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,0,1
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,2,0 Isr: 2,0,1
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 0,2,1
```

## Simulating node failure in k8s

Let’s get the node name where the first pod of Kafka Broker statefulset is running.
```Bash
kubectl get nodes
NODE=`kubectl get pods kafka-0 -n operator -o json | jq -r .spec.nodeName`
echo $NODE
# Output something like this
gke-cp53-cluster-cp53-node-pool-74668734-zf85
```
Now, simulate a node failure:
```Bash
kubectl cordon ${NODE}
kubectl get nodes
#output
gke-cp53-cluster-cp53-node-pool-74668734-zf85   Ready,SchedulingDisabled   <none>   74m   v1.13.11-gke.14
```
Continue todelete the pod kafka-0 running on the node that is cordoned off.
```Bash
kubectl get pods -n operator
kubectl delete pod kafka-0 -n operator
kubectl get pods -o wide -n operator | grep kafka
# Kafa-0 becomes up and running on e new node gke-cp53-cluster-cp53-node-pool-74668734-mv24
kafka-0                       1/1     Running   0          2m3s   10.12.8.2    gke-cp53-cluster-cp53-node-pool-74668734-mv24   <none>           <none>
kafka-1                       1/1     Running   0          19m    10.12.9.3    gke-cp53-cluster-cp53-node-pool-5f4ba227-p9xq   <none>           <none>
kafka-2                       1/1     Running   0          74m    10.12.15.3   gke-cp53-cluster-cp53-node-pool-e776ad48-71z5   <none>           <none>
# Check Nodes, the defected node is still defected
kubectl get nodes
# output
NAME                                            STATUS                     ROLES    AGE   VERSION
gke-cp53-cluster-cp53-node-pool-5f4ba227-7vb3   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-5f4ba227-bnkk   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-5f4ba227-p9xq   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-5f4ba227-wnf0   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-74668734-2qw1   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-74668734-c644   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-74668734-mv24   Ready                      <none>   79m   v1.13.11-gke.14
">>"gke-cp53-cluster-cp53-node-pool-74668734-zf85   Ready,SchedulingDisabled   <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-e776ad48-71z5   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-e776ad48-cvpj   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-e776ad48-ln23   Ready                      <none>   79m   v1.13.11-gke.14
gke-cp53-cluster-cp53-node-pool-e776ad48-w2d4   Ready                      <none>   79m   v1.13.11-gke.14
# That mean kafka-0 broker is running on a new node
kubectl get pods -o wide -n operator | grep gke-cp53-cluster-cp53-node-pool-74668734-mv24
```
Ok, Node and Broker is up and running, let's test the topic:
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output Broker 1 is missing
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 0       Replicas: 1,0,2 Isr: 0,2,1
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,0,1
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
        Topic: example  Partition: 3    Leader: 2       Replicas: 1,2,0 Isr: 2,0,1
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,0,1
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 0,2,1
```
In that case we have to rebalance the brokers again:
```bash
kubectl -n operator exec -it kafka-2 bash
# create a config file
cat << EOF > config.properties
confluent.license=
confluent.rebalancer.metrics.sasl.mechanism=PLAIN
confluent.rebalancer.metrics.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
confluent.rebalancer.metrics.bootstrap.servers=kafka:9071
confluent.rebalancer.metrics.security.protocol=SASL_PLAINTEXT
EOF
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output Broker are balanced
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,0,2 Isr: 2,1,0
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,1,0
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 2,1,0
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,2,0 Isr: 2,1,0
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,1,0
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 2,1,0
```
