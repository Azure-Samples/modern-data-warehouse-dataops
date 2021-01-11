locals {
  resource_name     = "${var.name}-${var.environment}"
  connection_string = tomap({ for item in var.event_hub_names : "${item}EvhConnection" => "@Microsoft.KeyVault(VaultName=kv-${local.resource_name};SecretName=${item};SecretVersion=)" })
  eventhub_names    = tomap({ for i, name in module.eventhubs : "${var.event_hub_names[i]}Evh" => name.eventhub_name })
  appsettings       = merge(local.connection_string, local.eventhub_names)
}
