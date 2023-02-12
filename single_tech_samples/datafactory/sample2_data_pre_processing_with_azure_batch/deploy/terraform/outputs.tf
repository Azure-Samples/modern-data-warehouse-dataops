output "virtual_network_name" {
  value = module.virtual_network.virtual_network_name
}

output "subnet_name" {
  value = module.virtual_network.subnet_name
}

output "key_vault_name" {
  value = module.key_vault.key_vault_name
}

output "adls_account_name" {
  value = module.adls.adls_account_name
}

output "batch_account_name" {
  value = module.azure_batch.batch_account_name
}
output "batch_storage_account_name" {
  value = module.batch_storage_account.storage_account_name
}

output "exec_pool_name" {
  value = module.azure_batch.exec_pool_name
}

output "orch_pool_name" {
  value = module.azure_batch.orch_pool_name
}

output "batch_account_url" {
  value = module.azure_batch.batch_account_url
}

output "managed_identity_name" {
  value = module.batch_managed_identity.managed_identity_name
}

output "container_registry_name" {
  value = module.container_registry.acr_name
}


output "data_factory_name" {
  value = module.data_factory.adf_name
}
