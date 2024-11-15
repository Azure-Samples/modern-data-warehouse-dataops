resource "azurerm_key_vault_secret" "secret" {
<<<<<<< HEAD
  name         = var.name
  value        = var.value
  key_vault_id = var.key_vault_id
=======
  name            = var.name
  value           = var.value
  key_vault_id    = var.key_vault_id
  expiration_date = var.expiration_date
  content_type    = var.content_type
  tags            = var.tags
>>>>>>> 2afc4f7bcf103231689f5fe5b302f5c46b87d507
}
