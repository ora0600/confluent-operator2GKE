# Create AWS K8s 

Applying this terraform deployment will create a K8s cluster with the following deployed:

* Tiller
* Confluent Platform

# Requirements
The following components are required:

* jq: e.g. 'brew install jq'
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): e.g. brew install kubernetes-cli (tested with 1.16.0)
* helm: e.g. `brew install kubernetes-helm` (tested with 2.14.3)
* [terraform (0.12)](https://www.terraform.io/downloads.html): e.g. brew install terraform
* [aws cli ](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for AWS Cloud: Tool that provides the primary CLI to AWS Cloud Platform
* [eksctl ](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) for AWS Cloud: Tool that provides the primary CLI to AWS EKS Cloud Service.

The setup is tested on Mac OS X.

Make sure to have updated versions, e.g. an older version of helm did not work.

## Configure AWS Account 

1) Create Service Keys and store in `terraform/aws/variables.tf` file. You will have to create an [API access key in aws](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/) first if you don't have one. Choose the right roles for your account. If something is missing terraform let you know. 
2) Change the file `variables.tf` in `terraform/aws` folder. Here you will find entries which have to fit with your environment. You have to set the right region, AZ count, the node count and access key and access secret. The others can stay default.

# Quick Start

1. Ensure Access Key/Secret is set in `terraform/aws/variables.tf`. 

2. Before starting terraform: change the file [variables.tf](variables.tf). Here you will find entries which have to fit with your environment. You have to set the right region, AZ count, the node count and access key and access secret. The others can stay default.

4. Run `helm init` to refresh the repo of Helm first.
Run `helm repo update` to refresh the repo of Helm first.

5. First Step: Create the environment in AWS Cloud: Create the EKS Cluster 
```bash
# create the AWS Cluster
terraform init
terraform plan
terraform apply
```
# Destroy Infrastructure

* Run 'terraform destroy' to stop and remove the created Kubernetes infrastructure
```bash
# destroy the EKS Cluster
terraform destroy
```
HINT:
* Double check in AWS Cloud Console if everything is destroyed: 
  Kubernetes Engine, Compute Engine and under Compute Engine please check also Disks and Instance Groups. Also Loadbalancers from the Hands-on.
* It seems to be that the ssd Disk from Confluent will not be deleted, so please delete manually in your AWS console UI.
* If the destroy takes more than 10 minutes then terraform is throwing an error. 
  Then you have to destory manually via AWS Cloud Console.
  * delete instance groups in Compute Engine
  * delete not attached Disks in Compute Engine
  * Delete cluster in Kubernetes Engine
