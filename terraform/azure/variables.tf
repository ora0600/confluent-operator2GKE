variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
    default = 7
}

variable "ssh_public_key" {
    default = "~/keys/cmutzlitz-key-azure.pub"
}

variable "dns_prefix" {
    default = "cp60"
}

variable cluster_name {
    default = "cp60-cluster"
}

variable resource_group_name {
    default = "azure-cp60"
}

variable location {
    default = "germanywestcentral"
}

variable cprovider {
    default = "azure"
}

#variable log_analytics_workspace_name {
#    default = "cp60LogAnalyticsWorkspaceName"
#}

## refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
#variable log_analytics_workspace_location {
#    default = "westcentral"
#}

## refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
#variable log_analytics_workspace_sku {
#    default = "PerGB2018"
#}