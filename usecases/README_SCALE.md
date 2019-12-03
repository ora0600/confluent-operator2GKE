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
## Check the k8s after scale down

One pod less for kafka broker:
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
# create a config file
cat << EOF > config.properties
confluent.license=
confluent.rebalancer.metrics.sasl.mechanism=PLAIN
confluent.rebalancer.metrics.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="test" password="test123";
confluent.rebalancer.metrics.bootstrap.servers=kafka:9071
confluent.rebalancer.metrics.security.protocol=SASL_PLAINTEXT
EOF
# run ADB 
confluent-rebalancer execute --zookeeper zookeeper:2181/kafka-operator --metrics-bootstrap-server kafka:9071 --throttle 10000000 --verbose --config-file config.properties --remove-broker-ids 2
# check status
confluent-rebalancer status --zookeeper zookeeper:2181/kafka-operator
# consume all the data
kafka-console-consumer --topic example --bootstrap-server kafka:9071 --consumer.config kafka.properties --from-beginning
```

## Scale up
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

oder so

helm upgrade \
    --install \
    --namespace operator $(HELM_COMMON_FLAGS) \
    --set kafka.replicas=$(GKE_BASE_KAFKA_REPLICAS) \
    --set kafka.enabled=true \
    kafka $(OPERATOR_PATH)helm/confluent-operator


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
## Check the k8s after scale down

One pod less for kafka broker:
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
As you can see the partitions are shared on only two brokers. We have to start auto data balancer.
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
# check the status 
confluent-rebalancer status --zookeeper zookeeper:2181/kafka-operator
# check the topic
kafka-topics --bootstrap-server kafka:9071 \
--command-config kafka.properties \
--describe --topic example
# consume all the data
kafka-console-consumer --topic example --bootstrap-server kafka:9071 --consumer.config kafka.properties --from-beginning
```
Everything is balance.