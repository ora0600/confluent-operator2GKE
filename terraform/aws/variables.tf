#
# Variables Configuration
#
variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "cluster-name" {
  default = "cp-53-cluster"
  type    = "string"
}

variable "node_count" {
  default = 12
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
