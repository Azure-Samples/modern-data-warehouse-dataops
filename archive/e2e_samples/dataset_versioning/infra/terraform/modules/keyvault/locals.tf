locals {
  adf_identity_secret_permissions  = ["Get"]
  client_config_secret_permissions = ["Get", "Set", "Delete", "Purge", "List", "Recover"]
}
