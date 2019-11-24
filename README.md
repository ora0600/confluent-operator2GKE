# Deploying Google Kubernetes Engine with Confluent Operator

Let's first understand the used components in this demo. Then install the required CLI tools. Finally setup the demo with just two commands.

## Installed Components

The following components will be installed (deployment in this order):

[terraform-gcp](terraform-gcp): A terraform script will create a GKE cluster with Tiller in Google cloud. This terraform setup will also run the `01_installConfluentPlatform.sh` Script for deploying confluent operator into GKE. A Confluent Cluster is setup, 3 Zookeeper, 3 Kafka Broker, 2 Schema Registry, 2 KSQL-Server, 1 Control Center.

## Requirements

The following components are required on your laptop to provison and install the demo (ideally in the tested versions, otherwise, you might have to fix errors):

* [jq](https://stedolan.github.io/jq/): Lightweight and flexible command-line JSON processor,  e.g. `brew install jq`
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): Kubernetes CLI to deploy applications, inspect and manage cluster resources,  e.g. `brew install kubernetes-cli` (tested with 1.16.0)
* Helm: Helps you manage Kubernetes applications - Helm Charts help you define, install, and upgrade even the most complex Kubernetes application, e.g. `brew install kubernetes-helm` (tested with 2.14.3)
* [terraform (0.12)](https://www.terraform.io/downloads.html): Enables you to safely and predictably create, change, and improve infrastructure (infrastructure independent, but currently only implemented GCP setup), e.g. `brew install terraform`
* [gcloud](https://cloud.google.com/sdk/docs/quickstart-macos): Tool that provides the primary CLI to Google Cloud Platform, e.g.  (always run `gcloud init` first)

Make sure to have up-to-date versions (see the tested versions above). For instance, an older version of helm or kubectl CLI did not work well and threw (sometimes confusing) exceptions.

The setup is tested on Mac OS X. We used Confluent Platform 5.3.1.

## Configure GCP Account and Project

1) Create account.json in `terraform-gcp` directory. You will have to create a [service account on GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) first if you don't have one. Choose the right roles and enable google API. If something is missing terraform let you know. If you already have a Service Account, you can go to your `GCP Console in the web browser --> IAM & admin --> Service Accounts --> Create or Select Key --> Download .json file --> Rename to account.json --> Copy to terraform-gcp directory`
2) Choose a `GCP project` or create a new one on your cloud console. Terraform will prompt you to specify your project name when applying.
3) Change the file `variables.tf` in terraform-gcp folder. Here you will find entries which have to fit with your environment. You have to set the right region, the node count and preemptible_nodes (cheaper). Mandatory change is `project`: Add your GCP project name or enter the correct GCP project name after terraform apply (it will ask). The others can stay default.

## Usage

1. Go to `terraform-gcp` directory
    * Run `helm init` if you are new with helm.
    * Run `helm repo update` to refresh the repo of Helm first.
    * Run `terraform init` (initializes the setup - only needed to be executed once on your laptop, not every time you want to re-create the infrastructure)
    * Run `terraform plan` (plans the setup)
    * Run `terraform apply` (sets up all required infrastructure on GCP - can take 10-20 minutes)
    * For a Confluent Control Center, KSQL, Schem Registry, REST Proxy and Kafka we use Google Load Balancers. Please change your /etc/hosts file as mentioned in the documentation [go to confluent](confluentREADME.md)
2. Monitoring and interactive queries
    * Go to [confluent](confluentREADME.md) Readme
    * Use the hints to connect Confluent Control Center or working with KSQL CLI for interactive queries

## Deletion of Demo Infrastructure

When done with the demo, go to `terraform-gcp` directory and run `terraform destroy` to stop and remove the created Kubernetes infrastructure. `Doublecheck the 'disks' in your GCP console`. If you had some errors, the script might not be able to delete all SDDs!

### Open Source and License Requirements

The *default configuration runs without any need for additional licenses*. We use open source Apache Kafka and additional Enterprise components which are included as trial version. 

Confluent components automatically include a 30 day trial license (not allowed for production usage). This license can be used without any limitations regarding scalability. You can see in Confluent Control Center how many days you have left. After 30 days, you also need to contact a Confluent person.


## TODOs - Not implemented as showcase yet on this gitpub project

Planned until end of November 2019:

    a) Showing Rolling Upgrade
    b) Showing Version migration
    c) Showing Security Setup