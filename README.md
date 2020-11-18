
CURRENTLY WORK IN PROGRESS for AZURE.

# Deploying Confluent Cluster with Confluent Operator into managed K8s (AWS and GCP)

Let's first understand the used components in this demo. Then install the required CLI tools. Finally setup the demo with just two commands.
Currently we will deploy Confluent Platform 6.0 clusters with Confluent Operator into GCP GKE, AWS EKS or Azure AKS (not yet implemented).
You will deploy the Infrastructure into cloud and based on this a couple of hands-on steps have to be executed.

## Installed Components

The following components will be installed (deployment in this order):

[terraform](terraform): A terraform script will create a GKE or EKS or AKS cluster in Google or AWS cloud. 
This terraform setup will also run the `01_installConfluentPlatform.sh` Script for deploying confluent operator into GKE or AWS or Azure. 
A Confluent Cluster is setup, 
* 3 Zookeeper, 
* 3 Kafka Broker, 
* 1 Schema Registry, 
* 1 KSQL-Server, 
* 1 connect
* 1 Control Center.

## Requirements

The following components are required on your laptop to provison and install the demo (ideally in the tested versions, otherwise, you might have to fix errors):

The following components are required:

* jq: e.g. 'brew install jq'
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): e.g. brew install kubernetes-cli (tested with 1.16.0)
* helm 3: e.g. brew reinstall helm (tested with 3.0.2) see [Migrate from Helm 2 to 3](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/), [install helm 3.0.2](https://helm.sh/docs/intro/install/) and [Helm 2 to Helm 3 Upgrade](https://runkiss.blogspot.com/2019/12/helm-2-to-helm-3-updates.html). In most cases, you just need to install Helm 3 and then add the stable Helm Repo: `helm repo add stable https://kubernetes-charts.storage.googleapis.com/'
* [terraform (0.12.19)](https://www.terraform.io/downloads.html): e.g. `brew install terraform`
* [GCloud CLI v. 277.0.0](https://cloud.google.com/sdk/docs/quickstart-macos) (run `gcloud init first`)
* [aws cli ](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for AWS Cloud: Tool that provides the primary CLI to AWS Cloud Platform
* [eksctl ](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) for AWS Cloud: Tool that provides the primary CLI to AWS EKS Cloud Service.
Make sure to have up-to-date versions (see the tested versions above). For instance, an older version of helm or kubectl CLI did not work well and threw (sometimes confusing) exceptions.
The setup is tested on Mac OS X. We used Confluent Platform 6.0.0

A typical Confluent Cluster will be deployed:
![Deployed k8 cluster](images/k8s_cluster.png)

## Goto Google Setup
Set up the cluster in GCP:
* [Google deployment with terraform](terraform/gcp)

## Goto AWS Setup
Setup the cluster in AWS
* [AWS deployment with terraform](terraform/aws)


## Following use cases can be executed 

Find a couple of use cases how to use Confluent Operator within a K8s deployment:
 * Deploy a 3 node Kafka Broker within 3 Availability Zones (Done via terraform deployment)
 * Check Confluent Cluster, see [Readme](usecases/confluentREADME.md)
 * Deploy Load Balancer to get external access to your confluent cluster [Readme](usecases/README_LB.md)
 * Scale down and Scale up the Confluent Cluster [Readme](usecases/README_SCALE.md)
 * Doing a version Upgrade from 6.0.0 to 5.5.1 [Readme](usecases/README_UPGRADE.md)
 * We will simulate some crashed and see what is happining [Readme](usecases/README_SelfHealing.md)
 * Finally we show CP 6.0 features with Operator [Readme](usecases/README_60_features.md)


# Open Source and License Requirements

The *default configuration runs without any need for additional licenses*. We use open source Apache Kafka and additional Enterprise components which are included as trial version. 

Confluent components automatically include a 30 day trial license (not allowed for production usage). This license can be used without any limitations regarding scalability. You can see in Confluent Control Center how many days you have left. After 30 days, you also need to contact a Confluent person.

You have to be clear that the deployment into public cloud vendors with generate costs on your site. Please check the terraform scipt to check the instance type we use. There will be k8s, compute, storage and network costs.