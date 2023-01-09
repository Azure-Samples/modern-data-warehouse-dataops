resource_group_name = "av-dataops-azure-dev"
address_space       = "10.0.0.0/16"
address_prefix      = "10.0.0.0/24"
location            = "centralindia"
adf_name            = "adf"
node_size           = "Standard_D8_v3"
acr_name = "avopsregistry"
acr_sku = "Premium"
container_name = "data"
tags = {
  environment = "dev",
}
name_suffix                       = "batch-identity"
batch_account_name                = "adaintbatchaccount"
exec_pool_name                    = "executionpool"
orch_pool_name                    = "orchestratorpool"
node_placement_exec_pool          = "Regional"
container_configuration_exec_pool = "DockerCompatible"
storage_image_reference_orch_pool = {
  publisher = "canonical"
  offer     = "0001-com-ubuntu-server-focal"
  sku       = "20_04-lts"
  version   = "latest"
}
storage_image_reference_exec_pool = {
  publisher = "microsoft-azure-batch"
  offer     = "ubuntu-server-container"
  sku       = "20-04-lts"
  version   = "latest"
}
endpoint_configuration = {
  backend_port          = 22
  frontend_port_range   = "1-49999"
  protocol              = "TCP"
  access                = "Deny"
  priority              = "150"
  source_address_prefix = "*"
}
data_lake_store_name = "avopsdata"
blob_storage_cors_origins = ["https://*.av.electric.com", "http://*.av.corp.electric.com", "https://*.av.corp.electric.com"]
is_hns_enabled           = true
nfsv3_enabled            = true
last_access_time_enabled = true
bypass                   = ["AzureServices"]
key_vault_name = "avopskv"
storage_account_name       = "avbatch"

