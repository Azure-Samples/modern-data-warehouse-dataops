resource "azurerm_batch_account" "batch_account" {
  name                                = var.batch_account_name
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
  name                = "${var.resource_group_name}-${var.orch_pool_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.ip_sku
  domain_name_label   = "${var.resource_group_name}-${var.orch_pool_name}-ip"
  tags                = var.tags
}

resource "azurerm_batch_pool" "orch_pool" {
  depends_on = [
    azurerm_batch_account.batch_account
  ]
  name                = "${var.resource_group_name}-${var.orch_pool_name}"
  resource_group_name = var.resource_group_name
  account_name        = var.batch_account_name
  display_name        = var.orch_pool_name
  vm_size             = var.vm_size_orch_pool
  node_agent_sku_id   = var.node_agent_sku_id_orch_pool
  max_tasks_per_node  = 16
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
    command_line       = file("./modules/startupTasks/orchestratorpool.sh")
    task_retry_maximum = 1
    wait_for_success   = true
    common_environment_properties = {
      storage_account_name        = var.adls_account_name
      container_name              = var.container_name
      env                         = var.tags.environment
      BATCH_INSIGHTS_DOWNLOAD_URL = "https://github.com/Azure/batch-insights/releases/download/v1.3.0/batch-insights"
      AZCOPY_CONCURRENCY_VALUE    = "AUTO"
    }
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
  name                = "${var.resource_group_name}-${var.exec_pool_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = var.ip_sku
  domain_name_label   = "${var.resource_group_name}-${var.exec_pool_name}-ip"
  tags                = var.tags
}

resource "azurerm_batch_pool" "exec_pool" {
  depends_on = [
    azurerm_batch_account.batch_account
  ]
  name                = "${var.resource_group_name}-${var.exec_pool_name}"
  resource_group_name = var.resource_group_name
  account_name        = var.batch_account_name
  display_name        = var.exec_pool_name
  vm_size             = var.vm_size_exec_pool
  node_agent_sku_id   = var.node_agent_sku_id_exec_pool
  max_tasks_per_node  = 32
  identity {
    type         = "UserAssigned"
    identity_ids = [var.batch_uami_id]
  }
  # node_placement {
  #   policy = var.node_placement_exec_pool
  # }
  storage_image_reference {
    publisher = var.storage_image_reference_exec_pool.publisher
    offer     = var.storage_image_reference_exec_pool.offer
    sku       = var.storage_image_reference_exec_pool.sku
    version   = var.storage_image_reference_exec_pool.version
  }
  container_configuration {
    type = var.container_configuration_exec_pool
    container_registries {
      user_assigned_identity_id = var.batch_uami_id
    }
  }
  start_task {
    command_line       = file("./modules/startupTasks/executionpool.sh")
    task_retry_maximum = 1
    wait_for_success   = true
    common_environment_properties = {
      storage_account_name        = var.adls_account_name
      container_name              = var.container_name
      env                         = var.tags.environment
      BATCH_INSIGHTS_DOWNLOAD_URL = "https://github.com/Azure/batch-insights/releases/download/v1.3.0/batch-insights"
      AZCOPY_CONCURRENCY_VALUE    = "AUTO"
    }
    user_identity {
      auto_user {
        elevation_level = "Admin"
        scope           = "Pool"
      }
    }
  }
  auto_scale {
    evaluation_interval = "PT10M"
    formula             = <<EOF
      startingNumberOfVMs = 0;
      // Ideally for extraction 1 bag files requires 27 task slots
      // 270 means 10 bag files will be procssed concurrently.
      tasksToBeRunConCurrently = 270;
      maxNumberofVMs = tasksToBeRunConCurrently/$TaskSlotsPerNode;
      // Get the pending tasks for the past X-number of minutes
      timeInterval = 7;
      // Get pending tasks for the past configured minutes.
      $samples = $ActiveTasks.GetSamplePercent(TimeInterval_Minute * timeInterval);
      // If we have fewer than 70 percent data points, we use the last sample point, otherwise we use the maximum of last sample point and the history average.
      $tasks = $samples < 70 ? max(0, $ActiveTasks.GetSample(1)) : max( $ActiveTasks.GetSample(1), avg($ActiveTasks.GetSample(TimeInterval_Minute * timeInterval)));
      minimumNodesRequired = ($tasks < $TaskSlotsPerNode && $tasks > 0) ? 1 : 0;
      //Batch does not support ceil/floor/round functions
      //0.7 is added so that adequate number of nodes is available. 
      //e.g if the desired number comes to be 3.8 and if we dont add 0.7 only 3 nodes will be scaled.
      desiredNodesRequired = ($tasks/$TaskSlotsPerNode) + 0.7;
      desiredNodesRequired = $tasks > $TaskSlotsPerNode  ? desiredNodesRequired  : minimumNodesRequired;
      $TargetLowPriorityNodes = min(maxNumberofVMs, desiredNodesRequired);
      $NodeDeallocationOption = taskcompletion;
    EOF
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
