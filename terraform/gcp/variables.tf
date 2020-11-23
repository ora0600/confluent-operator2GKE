variable "node_count" {
  default = 3
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}


variable "preemptible_nodes" {
  default = "false"
}

variable "daily_maintenance_window_start_time" {
  default = "02:00"
}

variable name {
  type = string
  default = "cp60-cluster"
  description = "Name for the GKE cluster"
}

variable "cprovider" {
  default = "gcp"
  description = "Terraform for Google Cloud"
}

variable project {
  type = string
  description = "The name of your GCP project to use"
}

