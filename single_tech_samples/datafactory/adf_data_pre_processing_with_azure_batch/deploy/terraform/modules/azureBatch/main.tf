resource "azurerm_batch_account" "batch_account" {
  name                                = "${var.batch_account_name}${var.tags.environment}${var.batch_account_suffix}"
  resource_group_name                 = var.resource_group_name
  location                            = var.location
  pool_allocation_mode                = var.pool_allocation_mode
  storage_account_id                  = var.storage_account_id
  storage_account_authentication_mode = var.storage_account_authentication_mode
  storage_account_node_identity       = var.batch_uami_id
  identity {
    type = var.identity_type
  }
  tags = var.tags
}

resource "azurerm_public_ip" "orch_pool_ip" {
  name                = "${var.orch_pool_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.ip_sku
  domain_name_label   = "${var.orch_pool_name}-ip"
  tags                = var.tags
}

resource "azurerm_batch_pool" "orch_pool" {
  depends_on = [
    azurerm_batch_account.batch_account
  ]
  name                = var.orch_pool_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_batch_account.batch_account.name
  display_name        = var.orch_pool_name
  vm_size             = var.vm_size_orch_pool
  node_agent_sku_id   = var.node_agent_sku_id_orch_pool
  max_tasks_per_node  = 8
  identity {
    type         = "UserAssigned"
    identity_ids = [var.batch_uami_id]
  }

  storage_image_reference {
    publisher = var.storage_image_reference_orch_pool.publisher
    offer     = var.storage_image_reference_orch_pool.offer
    sku       = var.storage_image_reference_orch_pool.sku
    version   = var.storage_image_reference_orch_pool.version
  }

  start_task {
    command_line       = "/bin/bash -c \"sudo apt-get update && apt-get -y install python3-pip && pip install azure-batch==12.0.0 azure-keyvault==4.2.0 azure-identity==1.11.0 pydantic==1.10.2 python-dotenv==0.21.0\""
    task_retry_maximum = 1
    wait_for_success   = true
    
    user_identity {
      auto_user {
        elevation_level = "Admin"
        scope           = "Pool"
      }
    }
  }

  fixed_scale {
    target_dedicated_nodes    = 1
    target_low_priority_nodes = 0
  }

  network_configuration {
    subnet_id = var.batch_subnet_id
    endpoint_configuration {
      name                = "${var.orch_pool_name}-block-ssh"
      backend_port        = var.endpoint_configuration.backend_port
      frontend_port_range = var.endpoint_configuration.frontend_port_range
      protocol            = var.endpoint_configuration.protocol
      network_security_group_rules {
        access                = var.endpoint_configuration.access
        priority              = var.endpoint_configuration.priority
        source_address_prefix = var.endpoint_configuration.source_address_prefix
      }
    }
    public_address_provisioning_type = "UserManaged"
    public_ips                       = [azurerm_public_ip.orch_pool_ip.id]
  }
}

resource "azurerm_public_ip" "exec_pool_ip" {
  name                = "${var.exec_pool_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.ip_sku
  domain_name_label   = "${var.exec_pool_name}-ip"
  tags                = var.tags
}

resource "azurerm_batch_pool" "exec_pool" {
  depends_on = [
    azurerm_batch_account.batch_account
  ]
  name                = "${var.exec_pool_name}"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_batch_account.batch_account.name
  display_name        = var.exec_pool_name
  vm_size             = var.vm_size_exec_pool
  node_agent_sku_id   = var.node_agent_sku_id_exec_pool
  max_tasks_per_node  = 8
  identity {
    type         = "UserAssigned"
    identity_ids = [var.batch_uami_id]
  }
  node_placement {
    policy = var.node_placement_exec_pool
  }
  storage_image_reference {
    publisher = var.storage_image_reference_exec_pool.publisher
    offer     = var.storage_image_reference_exec_pool.offer
    sku       = var.storage_image_reference_exec_pool.sku
    version   = var.storage_image_reference_exec_pool.version
  }
  container_configuration {
    type = var.container_configuration_exec_pool
    container_registries {
      registry_server           = var.registry_server
      user_assigned_identity_id = var.batch_uami_id
    }
  }
  start_task {
    command_line       = "/bin/bash -c 'sudo echo \"${var.adls_account_name}.blob.core.windows.net:/${var.adls_account_name}/${var.container_name} /${var.container_name} nfs defaults,sec=sys,vers=3,nolock,proto=tcp,nofail 0 0\" >> /etc/fstab && sudo mkdir -p /${var.container_name} && sudo apt-get update && sudo apt install -y nfs-common && mount /${var.container_name}'"
    task_retry_maximum = 1
    wait_for_success   = true    
    user_identity {
      auto_user {
        elevation_level = "Admin"
        scope           = "Pool"
      }
    }
  }
  fixed_scale {
    target_dedicated_nodes    = 1
    target_low_priority_nodes = 0
  }
  network_configuration {
    subnet_id = var.batch_subnet_id
    endpoint_configuration {
      name                = "${var.exec_pool_name}-block-ssh"
      backend_port        = var.endpoint_configuration.backend_port
      frontend_port_range = var.endpoint_configuration.frontend_port_range
      protocol            = var.endpoint_configuration.protocol
      network_security_group_rules {
        access                = var.endpoint_configuration.access
        priority              = var.endpoint_configuration.priority
        source_address_prefix = var.endpoint_configuration.source_address_prefix
      }
    }
    public_address_provisioning_type = "UserManaged"
    public_ips                       = [azurerm_public_ip.exec_pool_ip.id]
  }
}
