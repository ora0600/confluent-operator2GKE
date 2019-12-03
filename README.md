
CURRENTLY WORK IN PROGRESS

# Deploying Confluent Cluster with Confluent Operator into managed K8s (AWS and GCP)

Let's first understand the used components in this demo. Then install the required CLI tools. Finally setup the demo with just two commands.

## Installed Components

The following components will be installed (deployment in this order):

[terraform](terraform): A terraform script will create a GKE or EKS cluster with Tiller in Google or AWS cloud. This terraform setup will also run the `01_installConfluentPlatform.sh` Script for deploying confluent operator into GKE or AWS. A Confluent Cluster is setup, 3 Zookeeper, 3 Kafka Broker, 1 Schema Registry, 1 KSQL-Server, 1 Control Center.

## Requirements

The following components are required on your laptop to provison and install the demo (ideally in the tested versions, otherwise, you might have to fix errors):

* [jq](https://stedolan.github.io/jq/): Lightweight and flexible command-line JSON processor,  e.g. `brew install jq`
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): Kubernetes CLI to deploy applications, inspect and manage cluster resources,  e.g. `brew install kubernetes-cli` (tested with 1.16.0)
* Helm: Helps you manage Kubernetes applications - Helm Charts help you define, install, and upgrade even the most complex Kubernetes application, e.g. `brew install kubernetes-helm` (tested with 2.14.3)
* [terraform (0.12)](https://www.terraform.io/downloads.html): Enables you to safely and predictably create, change, and improve infrastructure (infrastructure independent, but currently only implemented GCP setup), e.g. `brew install terraform`
* [gcloud](https://cloud.google.com/sdk/docs/quickstart-macos) for Google Cloud: Tool that provides the primary CLI to Google Cloud Platform, e.g.  (always run `gcloud init` first)
* [aws cli ](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for AWS Cloud: Tool that provides the primary CLI to AWS Cloud Platform
* [eksctl ](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) for AWS Cloud: Tool that provides the primary CLI to AWS EKS Cloud Service.

Make sure to have up-to-date versions (see the tested versions above). For instance, an older version of helm or kubectl CLI did not work well and threw (sometimes confusing) exceptions.

The setup is tested on Mac OS X. We used Confluent Platform 5.3.1.

## Goto Google Setup

* [Google deployment with terraform](terraform/gcp)

## Goto AWS Setup

* [AWS deployment with terraform](terraform/aws)

## Usage

1. Go to `terraform` directory and choose your cloud platform
    * Run `helm init` to helm if not already done.
    * Run `helm repo update` to refresh the repo of Helm first.
    * Run `terraform init` (initializes the setup - only needed to be executed once on your laptop, not every time you want to re-create the infrastructure)
    * Run `terraform plan` (plans the setup)
    * Run `terraform apply` (sets up all required infrastructure on Cloud - can take 10-20 minutes)
2. Implement the use cases and the end of this side
    * Go to [confluent](confluentREADME.md) Readme
    * Use the hints to connect Confluent Control Center or working with KSQL CLI for interactive queries

## Deletion of Demo Infrastructure

When done with the demo, go to `terraform` directory, choose your cloud provicer and run `terraform destroy` to stop and remove the created Kubernetes infrastructure. `Doublecheck the 'disks' and loadbalancers in your cloud console`. If you had some errors, the script might not be able to delete all SDDs and Load Balancers!

## Following use cases can be executed 
In general how to use Confluent Operator within a K8s deployment:
 * Deploy a 3 node Kafka Broker within 3 Availability Zones (Done via terraform deployment)
 * Check Confluent Cluster, see [Readme](usecases/confluentREADME.md)
 * Deploy Load Balancer to get external access to your confluent cluster [Readme](usecases/README_LB.md)
 * Scale down and Scale up the Confluent Cluster [Readme](usecases/README_SCALE.md)
 * Doing a version Upgrade from 5.3.1 to 5.4.0 [Readme](usecases/README_UPGRADE.md)


# Open Source and License Requirements

The *default configuration runs without any need for additional licenses*. We use open source Apache Kafka and additional Enterprise components which are included as trial version. 

Confluent components automatically include a 30 day trial license (not allowed for production usage). This license can be used without any limitations regarding scalability. You can see in Confluent Control Center how many days you have left. After 30 days, you also need to contact a Confluent person.

You have to be clear that the deployment into public cloud vendors with generate costs on your site. Please check the terraform scipt to check the instance type we use. There will be k8s, compute, storage and network costs.