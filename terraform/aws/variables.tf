#
# Variables Configuration
#
variable "aws_access_key" {
  default = "put in our own key"
}

variable "aws_secret_key" {
  default = "put in your own secret"
}

variable "cluster-name" {
  default = "cp-60-cluster"
  type    = "string"
}

variable "node_count" {
  default = 15
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "az_count" {
  default = "3"
}


variable "cprovider" {
  default = "aws"
  description = "Terraform for AWS Cloud"
}
