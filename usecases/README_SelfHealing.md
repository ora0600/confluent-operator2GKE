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
# start in new terminal
kubectl get pods -n operator -w
# Cluster is restarting
kafka-0                       1/1     Running    0          57m
kafka-1                       0/1     Init:0/1   0          5s
kafka-2                       1/1     Running    0          55m
# running but not ready
kafka-0                       1/1     Running   0          58m
kafka-1                       0/1     Running   0          24s
kafka-2                       1/1     Running   0          55m
# Broker is up and running
kafka-0                       1/1     Running   0          58m
kafka-1                       1/1     Running   0          53s
kafka-2                       1/1     Running   0          56m
```
After  killing we will check the partitions on brokers again. You could also use the [control-center](http://controlcenter:9021/). The cluster will become into under-replication state, because one broker is missing. But broker will come up immmediatly after a while. No ADB need to execute. 
## Check on Terminal:
The terminal said: No, Broker 1 is missing for topic example. But control center said, no everything is fine. So, test, you will see that after a while everything is fine, and also ADB said everything in Balance.
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Output Broker 1 is missing
Topic: example  PartitionCount: 6       ReplicationFactor: 3    Configs: min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 0       Replicas: 0,1,2 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 1    Leader: 2       Replicas: 1,2,0 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 2    Leader: 2       Replicas: 2,0,1 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 3    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 4    Leader: 0       Replicas: 1,0,2 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 5    Leader: 2       Replicas: 2,1,0 Isr: 0,2,1      Offline: 
# Output all Broker are there
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
Topic: example  PartitionCount: 6       ReplicationFactor: 3    Configs: min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 0       Replicas: 0,1,2 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 1    Leader: 1       Replicas: 1,2,0 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 2    Leader: 2       Replicas: 2,0,1 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 3    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 4    Leader: 1       Replicas: 1,0,2 Isr: 0,2,1      Offline: 
        Topic: example  Partition: 5    Leader: 2       Replicas: 2,1,0 Isr: 0,2,1      Offline:
```
Cluster will balanced automatically


## Simulating node failure in k8s

Let’s get the node name where the first pod of Kafka Broker statefulset is running.
```Bash
kubectl get nodes
NODE=`kubectl get pods kafka-0 -n operator -o json | jq -r .spec.nodeName`
echo $NODE
# Output something like this
gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5
```
Now, simulate a node failure:
```Bash
kubectl cordon ${NODE}
kubectl get nodes
#output
gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5   Ready,SchedulingDisabled   <none>   90m   v1.16.13-gke.40
```
Continue to delete the pod kafka-0 running on the node that is cordoned off.
```Bash
kubectl get pods -n operator
kubectl delete pod kafka-0 -n operator
# in different terminal
kubectl get pods -o wide -n operator -w | grep kafka
# Kafa-0 becomes up and running on a new node gke-cp53-cluster-cp53-node-pool-74668734-mv24
kafka-0                        0/1     Terminating   0          36m   10.8.11.5   gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5   <none>           <none>
kafka-1                        1/1     Running       0          17m   10.8.8.6    gke-cp60-cluster-cp-node-pool-cp60-cl-bd07b188-vrhc   <none>           <none>
kafka-2                        1/1     Running       0          29m   10.8.7.6    gke-cp60-cluster-cp-node-pool-cp60-cl-7074d2bf-2rtk   <none>           <none>
kafka-0                        0/1     Terminating   0          36m   10.8.11.5   gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5   <none>           <none>
kafka-0                        0/1     Terminating   0          36m   10.8.11.5   gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5   <none>           <none>
kafka-0                        0/1     Pending       0          0s    <none>      <none>                                                <none>           <none>
kafka-0                        0/1     Pending       0          0s    <none>      gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-3pl0   <none>           <none>
kafka-0                        0/1     Init:0/1      0          1s    <none>      gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-3pl0   <none>           <none>
kafka-0                        0/1     PodInitializing   0          19s   10.8.10.7   gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-3pl0   <none>           <none>
kafka-0                        0/1     Running           0          20s   10.8.10.7   gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-3pl0   <none>           <none>
# Check Nodes, the defected node is still defected
kubectl get nodes
# output
NAME                                            STATUS                     ROLES    AGE   VERSION
gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-3pl0   Ready                      <none>   92m   v1.16.13-gke.401
">>"gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5   Ready,SchedulingDisabled   <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-tzqj   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-7074d2bf-2rtk   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-7074d2bf-89nb   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-7074d2bf-nwr3   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-bd07b188-2rg9   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-bd07b188-pqmq   Ready                      <none>   92m   v1.16.13-gke.401
gke-cp60-cluster-cp-node-pool-cp60-cl-bd07b188-vrhc   Ready                      <none>   92m   v1.16.13-gke.401
# That mean kafka-0 broker is running on a new node
kubectl get pods -o wide -n operator | grep gke-cp60-cluster-cp-node-pool-cp60-cl-6532322a-rfd5
```
Ok, Node and Broker is up and running, let's test the topic:
```bash
kubectl -n operator exec -it kafka-2 bash
# create a kafka.properties file
cat << EOF > kafka.properties
bootstrap.servers=kafka:9071
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
sasl.mechanism=PLAIN
security.protocol=SASL_PLAINTEXT
EOF
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
Topic: example  PartitionCount: 6       ReplicationFactor: 3    Configs: min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 0       Replicas: 0,1,2 Isr: 2,1,0      Offline: 
        Topic: example  Partition: 1    Leader: 1       Replicas: 1,2,0 Isr: 2,1,0      Offline: 
        Topic: example  Partition: 2    Leader: 2       Replicas: 2,0,1 Isr: 2,1,0      Offline: 
        Topic: example  Partition: 3    Leader: 0       Replicas: 0,2,1 Isr: 2,1,0      Offline: 
        Topic: example  Partition: 4    Leader: 1       Replicas: 1,0,2 Isr: 2,1,0      Offline: 
        Topic: example  Partition: 5    Leader: 2       Replicas: 2,1,0 Isr: 2,1,0      Offline: 

```
You can also try to delete the compute instance of such a cluster node with cloud provider cli tools (aws or gcloud). 