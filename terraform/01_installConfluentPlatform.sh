#!/usr/bin/env bash
set -e
REGION=${1}
PROVIDER=${2}

# set current directory of this script
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "MYDIR is ${MYDIR}"

# Deploy Kubernets Metric Server 
echo "Deploying K8s Matric Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
kubectl get deployment metrics-server -n kube-system

echo "Deploying K8s dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml

echo "Download Confluent Operator"
# check if Confluent Operator still exist
DIR="confluent-operator/"
if [[ -d "$DIR" ]]; then
  # Take action if $DIR exists. #
  echo "Operator is installed..."
  cd confluent-operator/
else
  mkdir confluent-operator
  cd confluent-operator/
  # CP 5.3
  #wget https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-20190912-v0.65.1.tar.gz
  #tar -xvf confluent-operator-20190912-v0.65.1.tar.gz
  #rm confluent-operator-20190912-v0.65.1.tar.gz
  # CP 5.4
  #wget https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-20200115-v0.142.1.tar.gz
  #tar -xvf confluent-operator-20200115-v0.142.1.tar.gz
  #rm confluent-operator-20200115-v0.142.1.tar.gz
  # CP 6.0
  wget https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-1.6.0-for-confluent-platform-6.0.0.tar.gz
  tar -xvf confluent-operator-1.6.0-for-confluent-platform-6.0.0.tar.gz
  rm confluent-operator-1.6.0-for-confluent-platform-6.0.0.tar.gz

  #cp ${MYDIR}/gcp.yaml helm/providers/
fi

cd helm/

echo "prepare Confluent Operator installation"
kubectl create namespace operator || true

echo "Install Confluent Operator"
# Operator
helm upgrade --install \
operator \
./confluent-operator -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set operator.enabled=true
echo "After Operator Installation: Check all pods..."
kubectl get pods -n operator
kubectl rollout status deployment -n operator cc-operator
kubectl get crd | grep confluent

echo "Install Confluent Zookeeper"
#zookeeper
helm upgrade --install \
zookeeper \
./confluent-operator -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set zookeeper.enabled=true
echo "After Zookeeper Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator zookeeper

echo "Install Confluent Kafka"
#kafka
helm upgrade --install \
kafka \
./confluent-operator -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set kafka.enabled=true 
echo "After Kafka Broker Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator kafka

echo "Install Confluent Schema Registry"
#schemaregistry
helm upgrade --install \
schemaregistry \
./confluent-operator -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set schemaregistry.enabled=true
echo "After Schema Registry Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator schemaregistry


echo "Install Confluent Connect"
# Kafka Connect
helm upgrade --install \
connect \
./confluent-operator -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set connect.enabled=true
echo "After Kafka Connect Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator connect

echo "Install Confluent KSQL"
# ksql
helm upgrade --install \
ksql \
./confluent-operator  -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set ksql.enabled=true 
echo "After KSQL Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator ksql

echo "Install Confluent Control Center"
# controlcenter
helm upgrade --install \
controlcenter \
./confluent-operator  -f ${MYDIR}/${PROVIDER}/${PROVIDER}.yaml \
--namespace operator \
--set controlcenter.enabled=true
echo "After Control Center Installation: Check all pods..."
kubectl get pods -n operator
sleep 10
kubectl rollout status sts -n operator controlcenter

echo "Create Topics on Confluent Platform for Test Generator"
# Create Kafka Property file in all pods
kubectl rollout status sts -n operator kafka
echo "deploy kafka.property file into all brokers"
kubectl -n operator exec -it kafka-0 -- bash -c "printf \"bootstrap.servers=kafka:9071\nsasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"test\" password=\"test123\";\nsasl.mechanism=PLAIN\nsecurity.protocol=SASL_PLAINTEXT\" > /opt/kafka.properties"
kubectl -n operator exec -it kafka-1 -- bash -c "printf \"bootstrap.servers=kafka:9071\nsasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"test\" password=\"test123\";\nsasl.mechanism=PLAIN\nsecurity.protocol=SASL_PLAINTEXT\" > /opt/kafka.properties"
kubectl -n operator exec -it kafka-2 -- bash -c "printf \"bootstrap.servers=kafka:9071\nsasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"test\" password=\"test123\";\nsasl.mechanism=PLAIN\nsecurity.protocol=SASL_PLAINTEXT\" > /opt/kafka.properties"

# Create Topic sensor-data
echo "Create Topic sensor-data"
kubectl -n operator exec -it kafka-0 -- bash -c "kafka-topics --bootstrap-server kafka:9071 --command-config kafka.properties --create --topic sensor-data --replication-factor 3 --partitions 10 --config retention.ms=7200000"
# list Topics
kubectl -n operator exec -it kafka-0 -- bash -c "kafka-topics --bootstrap-server kafka:9071 --list --command-config kafka.properties"
# Create STREAMS
# CURL CREATE
echo "CREATE STREAM SENSOR_DATA_S"
kubectl -n operator exec -it ksql-0 -- bash -c "curl -X \"POST\" \"http://ksql:8088/ksql\" \
     -H \"Content-Type: application/vnd.ksql.v1+json; charset=utf-8\" \
     -d $'{
  \"ksql\": \"CREATE STREAM SENSOR_DATA_S (coolant_temp DOUBLE, intake_air_temp DOUBLE, intake_air_flow_speed DOUBLE, battery_percentage DOUBLE, battery_voltage DOUBLE, current_draw DOUBLE, speed DOUBLE, engine_vibration_amplitude DOUBLE, throttle_pos DOUBLE, tire_pressure_1_1 BIGINT, tire_pressure_1_2 BIGINT, tire_pressure_2_1 BIGINT, tire_pressure_2_2 BIGINT, accelerometer_1_1_value DOUBLE, accelerometer_1_2_value DOUBLE, accelerometer_2_1_value DOUBLE, accelerometer_2_2_value DOUBLE, control_unit_firmware BIGINT, coolantTemp DOUBLE, intakeAirTemp DOUBLE, intakeAirFlowSpeed DOUBLE, batteryPercentage DOUBLE, batteryVoltage DOUBLE, currentDraw DOUBLE, engineVibrationAmplitude DOUBLE, throttlePos DOUBLE, tirePressure11 BIGINT, tirePressure12 BIGINT, tirePressure21 BIGINT, tirePressure22 BIGINT, accelerometer11Value DOUBLE, accelerometer12Value DOUBLE, accelerometer21Value DOUBLE, accelerometer22Value DOUBLE, controlUnitFirmware BIGINT) WITH (kafka_topic=\'sensor-data\', value_format=\'JSON\');\",
  \"streamsProperties\": {}
}'"
echo "CREATE STREAM SENSOR_DATA_S_AVRO"
kubectl -n operator exec -it ksql-0 -- bash -c "curl -X \"POST\" \"http://ksql:8088/ksql\" \
     -H \"Content-Type: application/vnd.ksql.v1+json; charset=utf-8\" \
     -d $'{
  \"ksql\": \"CREATE STREAM SENSOR_DATA_S_AVRO WITH (VALUE_FORMAT=\'AVRO\') AS SELECT * FROM SENSOR_DATA_S;\",
  \"streamsProperties\": {}
}'"
echo "CREATE STREAM SENSOR_DATA_S_AVRO_REKEY"
kubectl -n operator exec -it ksql-0 -- bash -c "curl -X \"POST\" \"http://ksql:8088/ksql\" \
     -H \"Content-Type: application/vnd.ksql.v1+json; charset=utf-8\" \
     -d $'{
  \"ksql\": \"CREATE STREAM SENSOR_DATA_S_AVRO_REKEY AS SELECT ROWKEY as CAR, * FROM SENSOR_DATA_S_AVRO PARTITION BY CAR;\",
  \"streamsProperties\": {}
}'"
echo "CREATE TABLE SENSOR_DATA_EVENTS_PER_5MIN_T"
kubectl -n operator exec -it ksql-0 -- bash -c "curl -X \"POST\" \"http://ksql:8088/ksql\" \
     -H \"Content-Type: application/vnd.ksql.v1+json; charset=utf-8\" \
     -d $'{
  \"ksql\": \"CREATE TABLE SENSOR_DATA_EVENTS_PER_5MIN_T AS SELECT car, count(*) as event_count FROM SENSOR_DATA_S_AVRO_REKEY WINDOW TUMBLING (SIZE 5 MINUTE) GROUP BY car;\",
  \"streamsProperties\": {}
}'"
echo "####################################"
echo "## Confluent Deployment finshed ####"
echo "####################################"
