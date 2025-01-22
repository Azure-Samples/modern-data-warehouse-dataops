resource "random_string" "random_name" {
  length  = 5
  lower   = true
  numeric = false
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name_prefix}-${var.resource_name}-rest-${random_string.random_name.result}"
  location = var.resource_group_location
}

module "acr" {
  source         = "../modules/acr"
  resource_group = azurerm_resource_group.rg.name
  resourcename   = "${var.resource_name}${random_string.random_name.result}"
  location       = var.resource_group_location
}

module "dockerbuild" {
  source         = "../modules/dockerbuild"
  image          = var.image
  image_tag      = var.image_tag
  resource_group = azurerm_resource_group.rg.name
  registry       = module.acr.AzureContainerRegistry
  depends_on     = [module.acr]
}

module "aci-rest" {
  source         = "../modules/aci-rest"
  resource_group = azurerm_resource_group.rg.name
  registry       = module.acr.AzureContainerRegistry
  image          = var.image
  image_tag      = var.image_tag
  depends_on     = [module.dockerbuild]
}

output "container_ipv4_address" {
  value = module.aci-rest.container_ipv4_address
}
