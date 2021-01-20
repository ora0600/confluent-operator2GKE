# Create AWS K8s 

Applying this terraform deployment will create a K8s cluster with the following deployed:
* Confluent Platform

# Requirements
The following components are required:

* jq: e.g. 'brew install jq'
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): e.g. brew install kubernetes-cli (tested with 1.19.4)
* [terraform (0.12.19)](https://www.terraform.io/downloads.html): e.g. brew install terraform
* [aws cli ](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for AWS Cloud: Tool that provides the primary CLI to AWS Cloud Platform
* [eksctl ](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html) for AWS Cloud: Tool that provides the primary CLI to AWS EKS Cloud Service. We use to work with version 0.31

The setup is tested on Mac OS X.

Make sure to have updated versions.

## Configure AWS Account 

1) Create Service Keys and store in `terraform/aws/variables.tf` file. You will have to create an [API access key in aws](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/) first if you don't have one. Choose the right roles for your account. If something is missing terraform let you know. 
2) Change the file `variables.tf` in `terraform/aws` folder. Here you will find entries which have to fit with your environment. You have to set the right region, AZ count, the node count and access key and access secret. The others can stay default.

# Quick Start

1. Ensure our `~/.aws/credentials` are setup correctly. Execute `aws configure` and set APK Key, API Scret, Region to `eu-central-1` and output to `json`. 

2. Ensure Access Key/Secret is set in `terraform/aws/variables.tf`. 

3. Run `helm repo update` to refresh the repo of Helm first.

4. Before starting terraform: change the file [variables.tf](variables.tf). Here you will find entries which have to fit with your environment. You have to set the right region, AZ count, the node count and access key and access secret. The others can stay default.

5. First Step: Create the environment in AWS Cloud: Create the EKS Cluster 
```bash
# create the AWS Cluster
terraform init
terraform plan
terraform apply
```
6. go to [use cases](https://github.com/ora0600/confluent-operator2GKE#following-use-cases-can-be-executed) and start your hands-on

# Destroy Infrastructure

We do a force delete. For this you need eksctl 0.31 or later. [Install/Upgrade](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html#installing-eksctl)

* Run 'terraform destroy' to stop and remove the created Kubernetes infrastructure
```bash
# destroy the EKS Cluster
terraform destroy
```
Because the destroy of node cluster takes a while, terraform will throw an error. Check if node pool is in deleting status. Wait and execute again:
```bash
# again destroy after node pool is deleted
terraform destroy
rm -r confluent-operator/
```

If this is happeing check if node cluster is deleting.
The volumes will not deleted by terraform destroy. So, please delete all dynamic PVC volumes in AWS console.
And also check if the kubernetes loadbalancer are deleted, if not delete from AWS console.
A VPC did not generate any costs, but also the VPC and subnet can not be deleted by `terraform destroy`, so please delete VPC `terraform-eks-cp60-node` in aws console, if you want.
Delete manually:
```bash
aws eks list-nodegroups --cluster-name cp-60-cluster
aws eks delete-nodegroup --nodegroup-name cp60 --cluster-name cp-60-cluster
aws eks delete-cluster --name cp-60-cluster
```

HINT:
* Double check in AWS Cloud Console if everything is destroyed: 
  Kubernetes Engine, Nodepool and under Compute Engine please check also Volumes, VPC and Internet Gateway. Also Loadbalancers from the Hands-on.
* It seems to be that the ssd Disk from Confluent will not be deleted, so please delete manually in your AWS console UI.
* If the destroy takes more than 10 minutes then terraform is throwing an error. 
  Then you have to destory manually via AWS Cloud Console.
  * delete instance groups in Compute Engine
  * delete not attached Disks in Compute Engine
  * Delete cluster in Kubernetes Engine
