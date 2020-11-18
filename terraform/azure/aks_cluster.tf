resource "azurerm_resource_group" "cp60" {
    name     = var.resource_group_name
    location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

#resource "azurerm_log_analytics_workspace" "cp60" {
#    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
#    name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
#    location            = var.log_analytics_workspace_location
#    resource_group_name = azurerm_resource_group.cp60.name
#    sku                 = var.log_analytics_workspace_sku
#}

#resource "azurerm_log_analytics_solution" "cp60" {
#    solution_name         = "ContainerInsights"
#    location              = azurerm_log_analytics_workspace.cp60.location
#    resource_group_name   = azurerm_resource_group.cp60.name
#    workspace_resource_id = azurerm_log_analytics_workspace.cp60.id
#    workspace_name        = azurerm_log_analytics_workspace.cp60.name#
#
#    plan {
#        publisher = "Microsoft"
#        product   = "OMSGallery/ContainerInsights"
#    }
#}

resource "azurerm_kubernetes_cluster" "cp60" {
    name                = var.cluster_name
    location            = azurerm_resource_group.cp60.location
    resource_group_name = azurerm_resource_group.cp60.name
    dns_prefix          = var.dns_prefix

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_D3_v2"
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    #addon_profile {
    #    oms_agent {
    #    enabled                    = true
    #    log_analytics_workspace_id = azurerm_log_analytics_workspace.cp60.id
    #    }
    #}

    network_profile {
    load_balancer_sku = "Standard"
    network_plugin = "kubenet"
    }

    tags = {
        Environment = "Development"
    }
}