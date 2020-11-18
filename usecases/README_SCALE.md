# Scale down and up of Confluent Cluster

Try first to scale down and afterwards to scale up again:

## Scale down

First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas to 2 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/aws.yaml`
```bash
cd terraform/aws/
vi aws.yaml
kafka:
  name: kafka
  replicas: 2
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../aws.yaml \
 --namespace operator \
 --set kafka.enabled=true
```

### GCP
For GCP we will use `terraform/gcp/gcp.yaml`
```bash
cd terraform/gcp/
vi gcp.yaml
kafka:
  name: kafka
  replicas: 2
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../gcp.yaml \
 --namespace operator \
 --set kafka.enabled=true
```
Always the highest broker will be killed: in our casse broker-2

## Check the k8s after scale down

One pod less for kafka broker:
```bash
kubectl get pods -n operator
# check events running after upgrade
kubectl get events --sort-by=.metadata.creationTimestamp -n operator
```
Check the partitions of the topic examples:
```bash
kubectl -n operator exec -it kafka-0 bash
# describe topic or just check control center http://controlcenter:9021/
echo "bootstrap.servers=kafka:9071
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
sasl.mechanism=PLAIN
security.protocol=SASL_PLAINTEXT" > kafka.properties
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
```
The setup is as followed: ReplicationFactor:3 for all topics. Check control center [http://controlcenter:9021/](http://controlcenter:9021/). Because of the Replication-Factor setup. Please do now a Scale-up to 3 Brokers

## Scale up back to 3 Broker
First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas back to 3 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/aws.yaml`
```bash
cd terraform/aws
vi aws.yaml
kafka:
  name: kafka
  replicas: 3
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../aws.yaml \
 --namespace operator \
 --set kafka.enabled=true
```
### GCP

For GCP we will use `terraform/gcp/gcp.yaml`
```bash
cd terraform/gcp
vi gcp.yaml
kafka:
  name: kafka
  replicas: 3
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../gcp.yaml \
 --namespace operator \
 --set kafka.enabled=true
```
## Check the k8s after scale up

One pod more for kafka broker again 3 Brokers:
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
As you can see the partitions are shared on all three brokers and Controlcenter [http://controlcenter:9021/](http://controlcenter:9021/) takes a while to show that everything is in balance.
```bash
# consume all the data
kafka-console-consumer --topic example --bootstrap-server kafka:9071 --consumer.config kafka.properties --from-beginning
```

## Scale up to 4 Brokers
First edit the provider yaml file. It is aws.yaml or gcp.yaml and change kafka replicas back to 4 and run the oprator to scale.

### AWS
For AWS we will use : `terraform/aws/aws.yaml`
```bash
cd terraform/aws
vi aws.yaml
kafka:
  name: kafka
  replicas: 4
```
Now, run the oprator to scale down:
```bash
cd terraform/aws/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../aws.yaml \
 --namespace operator \
 --set kafka.enabled=true
```
### GCP

For GCP we will use `terraform/gcp/gcp.yaml`
```bash
cd terraform/gcp
vi gcp.yaml
kafka:
  name: kafka
  replicas: 4
```
Now, run the oprator to scale down:
```bash
cd terraform/gcp/confluent-operator/helm/
helm upgrade --install \
kafka \
./confluent-operator  -f ../../gcp.yaml \
 --namespace operator \
 --set kafka.enabled=true
```
## Check the k8s after scale up to 4 Brokers

One pod more for kafka broker in total 4:
```
kubectl get pods -n operator
kubectl get nodes
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
Everything is balance. You can also check [control center](http://controlcenter:9021/) and check if everything in balance.
