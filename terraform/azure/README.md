# Create Azure K8s AKS

Applying this terraform deployment will create an Azure K8s cluster with the following deployed:
* Confluent Platform

# Requirements
The following components are required:

* jq: e.g. 'brew install jq'
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): e.g. brew install kubernetes-cli (tested with 1.19.4)
* [terraform (0.12.19)](https://www.terraform.io/downloads.html): e.g. brew install terraform
* [az cli ](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos) for Azure Cloud: Tool that provides the primary CLI to Azure Cloud Platform

The setup is tested on Mac OS X.
Make sure to have updated versions.

## Configure Azure Account 
First of all you need working Azure account.
1) create SSH key for Azure in your own Resource group `cmutzlitz`(or your own resource Group) in location `Germany West Central`. Change the ssh key entry `variable "ssh_public_key"` in [variables.tf](variables.tf)

2) Configure Azure Account and Create Service Principal
  * Login:  `az login`
  * set subscription ID `az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>"`
  * Create Service Principal Account `az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>"` Please save the output, we need to set env-vars with `<service-principal-appid>` and  '<service-principal-password>', Enter service accounts in [env-vars](env-vars.sample) `source env-vars`

3) Change the file `variables.tf` if necessary in `terraform/azure` folder. Here you will find entries which have to fit with your environment. You have to set the right location, ssh key, the node count and access key and access secret. The others can stay default.

# Quick Start

0. Check your limits in azure for Compute VM (vCPUs) for 7 agents/nodes we need in total 14 vCPUs. My limit is set to 20.

1. Ensure your account `az login` is working. 

2. Run `helm repo update` to refresh the repo of Helm first.

3. Before starting terraform: change the file [variables.tf](variables.tf). Here you will find entries which have to fit with your environment. You have to set the right location, node count, ssh key name etc. 

4. First Step: Create the environment in Azure Cloud: Create the AKS Cluster 
```bash
# create the Azure AKS Cluster
terraform init
terraform plan
terraform apply
```
6. go to [use cases](https://github.com/ora0600/confluent-operator2GKE#following-use-cases-can-be-executed) and start your hands-on

# Destroy Infrastructure

We do a force delete. For this you need eksctl 0.31 or later. [Install/Upgrade](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html#installing-eksctl)

* Run 'terraform destroy' to stop and remove the created Kubernetes infrastructure
```bash
# destroy the AKS Cluster
terraform destroy
```
The destroy of the complete cluster takes a while. Please double check in Azure Portal under all resources, if everything is destroyed:
```bash
# delete operator in terraform/azure
rm -r confluent-operator/
```
