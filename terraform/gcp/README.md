# Create GCP K8s 

Applying this terraform deployment will create a K8s cluster with the following deployed:

* Tiller
* Confluent Platform

# Requirements
The following components are required:

* jq: e.g. 'brew install jq'
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): e.g. brew install kubernetes-cli (tested with 1.16.0)
* helm: e.g. `brew install kubernetes-helm` (tested with 2.14.3)
* [terraform (0.12)](https://www.terraform.io/downloads.html): e.g. brew install terraform
* [GCloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos) (run `gcloud init` first)

The setup is tested on Mac OS X.

Make sure to have updated versions, e.g. an older version of helm did not work.

## Configure GCP Account and Project

1) Create account.json in `terraform-gcp` directory. You will have to create a [service account on GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) first if you don't have one. Choose the right roles and enable google API. If something is missing terraform let you know. If you already have a Service Account, you can go to your `GCP Console in the web browser --> IAM & admin --> Service Accounts --> Create or Select Key --> Download .json file --> Rename to account.json --> Copy to terraform-gcp directory`
2) Choose a `GCP project` or create a new one on your cloud console. Terraform will prompt you to specify your project name when applying. Do `gcloud init` and set the right GCP project.
3) Change the file `variables.tf` in `terraform/gcp` folder. Here you will find entries which have to fit with your environment. You have to set the right region, the node count and preemptible_nodes (cheaper). Mandatory change is `project`: Add your GCP project name or enter the correct GCP project name after terraform apply (it will ask). The others can stay default.

# Quick Start

1. Ensure account.json is in this folder. You will have to [create a service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) on GCP first. Choose the right roles and enable google API. If something is missing terraform let you know.

2. Choose a GCP project or create a new one on your cloud console. Terraform will prompt you to specify your project name when applying. But you have to set the right GCP project before executing terraform:
```bash
gloud init
# output looks like this: Switch if necessary
Welcome! This command will take you through the configuration of gcloud.

Settings from your current configuration [default] are:
compute:
  region: us-west1
  zone: us-west1-b
core:
  account: your email
  disable_usage_reporting: 'True'
  project: ypur project name

Pick configuration to use:
 [1] Re-initialize this configuration [default] with new settings 
 [2] Create a new configuration
 [3] Switch to and re-initialize existing configuration: [your different project]
Please enter your numeric choice:  
```

3. Before starting terraform: change the file [variables.tf](variables.tf). Here you will find entries which have to fit with your environment. You have to set the right region, the node count and preemptible_nodes.

4. Run `helm init` to refresh the repo of Helm first.
Run `helm repo update` to refresh the repo of Helm first.

5. First Step: Create the environment in Google Cloud: Create the GKE Cluster (you have to enter the 
project name)
```bash
# create the GKE Cluster
terraform init
terraform plan
terraform apply
```
6. Follow the  Information to work with the Confluent Setup [go to confluent](../../confluentREADME.md)

# Destroy Infrastructure

* Run 'terraform destroy' to stop and remove the created Kubernetes infrastructure
```bash
# destroy the GKE Cluster, enter the project name
terraform destroy
```
HINT:
* Double check in Google Cloud Console if everything is destroyed: 
  Kubernetes Engine, Compute Engine and under Compute Engine please check also Disks and Instance Groups.
* It seems to be that the ssd Disk from Confluent will not be deleted, so please delete manually in your google console UI.
* If the destroy takes more than 10 minutes then terraform is throwing an error. 
  Then you have to destory manually via Google Cloud Console.
  * delete instance groups in Compute Engine
  * delete not attached Disks in Compute Engine
  * Delete cluster in Kubernetes Engine
