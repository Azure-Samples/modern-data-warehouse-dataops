resource "azuredevops_serviceendpoint_azurerm" "azurerm" {
  project_id                             = var.project_id
  service_endpoint_name                  = var.service_endpoint_name
  service_endpoint_authentication_scheme = var.service_endpoint_authentication_scheme

  dynamic "credentials" {
    for_each = var.service_endpoint_authentication_scheme == "ServicePrincipal" ? [1] : []
    content {
      serviceprincipalid  = var.service_principal_id
      serviceprincipalkey = var.service_principal_key
    }
  }

  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = var.subscription_name
}
