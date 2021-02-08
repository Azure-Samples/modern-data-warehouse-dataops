locals {
  resource_name       = "${var.name}-${var.environment}"
  connection_string   = tomap({ for item in var.event_hub_names : "${item}EvhConnection" => "@Microsoft.KeyVault(VaultName=kv-${local.resource_name};SecretName=${item}-conn;SecretVersion=)" })
  eventhub_names      = tomap({ for i, name in module.eventhubs : "${var.event_hub_names[i]}Evh" => name.eventhub_name })
  instrumentation_key = tomap({ APPINSIGHTS_INSTRUMENTATIONKEY = "@Microsoft.KeyVault(VaultName=kv-${local.resource_name};SecretName=${var.app_insights_name};SecretVersion=)" })
  subscription_id     = tomap({ subscription_id = data.azurerm_client_config.current.subscription_id })
  appsettings         = merge(local.connection_string, local.eventhub_names, local.instrumentation_key, local.subscription_id)
}
