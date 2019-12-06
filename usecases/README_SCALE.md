# Scale down and up of Confluent Cluster

Try first to scale down and afterwards to scale up again:

## Scale down

First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas to 2 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/confluent-operator/helm/provider/aws.yaml`
```bash
cd terraform/aws/confluent-operator/helm/
vi providers/aws.yaml
kafka:
  name: kafka
  replicas: 2
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade -f \
./providers/aws.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```

### GCP
For GCP we will use `terraform/gcp/confluent-operator/helm/provider/gcp.yaml`
```bash
cd terraform/gcp/confluent-operator/helm/
vi providers/gcp.yaml
kafka:
  name: kafka
  replicas: 2
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade -f \
./providers/gcp.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```
Always the highest broker will be killed: in our casse broker-2

## Check the k8s after scale down

One pod less for kafka broker:
```
kubectl get pods -n operator
# check events running after upgrade
kubectl get events --sort-by=.metadata.creationTimestamp -n operator
```
Check the partitions of the topic examples:
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic or just check control center http://controlcenter:9021/
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# output: See replicas still on broker 2, 6 partition are under replication 
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,0,2 Isr: 1,0
        Topic: example  Partition: 1    Leader: 1       Replicas: 2,1,0 Isr: 1,0
        Topic: example  Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 1,0
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,2,0 Isr: 1,0
        Topic: example  Partition: 4    Leader: 0       Replicas: 2,0,1 Isr: 1,0
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 1,0
# create a config file
cat << EOF > config.properties
confluent.license=
confluent.rebalancer.metrics.sasl.mechanism=PLAIN
confluent.rebalancer.metrics.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
confluent.rebalancer.metrics.bootstrap.servers=kafka:9071
confluent.rebalancer.metrics.security.protocol=SASL_PLAINTEXT
EOF
# run ADB
confluent-rebalancer execute \
--zookeeper zookeeper:2181/kafka-operator \
--metrics-bootstrap-server kafka:9071 \
--throttle 10000000 \
--verbose \
--config-file config.properties \
--remove-broker-ids 2
# ADB failed
```
The setup is as followed: ReplicationFactor:3 for all topics. Check control center [http://controlcenter:9021/](http://controlcenter:9021/). Because of the Replication-Factor setup ADB is not able to get all the metrics. So, the Balancer can't help here. Please do now a Scale-up to 3 Brokers

## Scale up back to 3 Broker
First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas back to 3 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/confluent-operator/helm/provider/aws.yaml`
```bash
cd terraform/aws/confluent-operator/helm/
vi providers/aws.yaml
kafka:
  name: kafka
  replicas: 3
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade -f \
./providers/aws.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```
### GCP

For GCP we will use `terraform/gcp/confluent-operator/helm/provider/gcp.yaml`
```bash
cd terraform/gcp/confluent-operator/helm/
vi providers/gcp.yaml
kafka:
  name: kafka
  replicas: 3
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade -f \
./providers/gcp.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```
## Check the k8s after scale up

One pod more for kafka broker:
```
kubectl get pods -n operator
```
Check the partitions of the topic examples:
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
```
As you can see the partitions are shared on all three brokers and Controlcenter [http://controlcenter:9021/](http://controlcenter:9021/) takes a while to show that verything is in balance. Check also auto data balancer.
```bash
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
# Output
The cluster is already balanced, exiting.
# consume all the data
kafka-console-consumer --topic example --bootstrap-server kafka:9071 --consumer.config kafka.properties --from-beginning
```
Everything is balance.

## Scale up to 4 Brokers
First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas back to 4 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/confluent-operator/helm/provider/aws.yaml`
```bash
cd terraform/aws/confluent-operator/helm/
vi providers/aws.yaml
kafka:
  name: kafka
  replicas: 4
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade -f \
./providers/aws.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```
### GCP

For GCP we will use `terraform/gcp/confluent-operator/helm/provider/gcp.yaml`
```bash
cd terraform/gcp/confluent-operator/helm/
vi providers/gcp.yaml
kafka:
  name: kafka
  replicas: 4
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade -f \
./providers/gcp.yaml \
--set kafka.enabled=true \
kafka \
./confluent-operator
```
## Check the k8s after scale up to 4 Brokers

One pod more for kafka broker:
```
kubectl get pods -n operator
```
It could happen that not enough nodes are available. Then add a new node via Cloud Console UI of your Cloud Provider.
You will see that if pods kafka-3 is pending. In that the node-pool resize will continue the POD creation of Broker-3 

Check the partitions of the topic examples:
```bash
kubectl -n operator exec -it kafka-0 bash
# create a kafka.properties file if missing
cat << EOF > kafka.properties
bootstrap.servers=kafka:9071
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
sasl.mechanism=PLAIN
security.protocol=SASL_PLAINTEXT
EOF
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
```
As you can see the partitions are shared on all three brokers but now we have 4 Brokers. In that case Auto Data Balancer need to be execute.
```bash
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
# Enter y to execute the plan
# check the status of ADB
confluent-rebalancer status --zookeeper zookeeper:2181/kafka-operator
# describe topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# Now also broker 3 has partitions
Topic:example   PartitionCount:6        ReplicationFactor:3     Configs:min.insync.replicas=2,message.format.version=2.3-IV1,max.message.bytes=2097164
        Topic: example  Partition: 0    Leader: 1       Replicas: 1,3,2 Isr: 2,1,3
        Topic: example  Partition: 1    Leader: 2       Replicas: 2,1,0 Isr: 2,1,0
        Topic: example  Partition: 2    Leader: 3       Replicas: 3,2,1 Isr: 2,1,3
        Topic: example  Partition: 3    Leader: 1       Replicas: 1,2,3 Isr: 2,1,3
        Topic: example  Partition: 4    Leader: 2       Replicas: 2,0,1 Isr: 2,1,0
        Topic: example  Partition: 5    Leader: 0       Replicas: 0,1,2 Isr: 2,1,0
# consume all the data
kafka-console-consumer --topic example --bootstrap-server kafka:9071 --consumer.config kafka.properties --from-beginning
```
Everything is balance.
