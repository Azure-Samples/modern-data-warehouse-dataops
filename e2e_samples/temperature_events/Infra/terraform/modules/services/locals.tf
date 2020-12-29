locals {
  resource_name = "${var.name}-${var.environment}"
  appsettings   = { for item in var.list1 : item => "@Microsoft.KeyVault(VaultName=kv-${local.resource_name};SecretName=${item};SecretVersion=)" }
}
