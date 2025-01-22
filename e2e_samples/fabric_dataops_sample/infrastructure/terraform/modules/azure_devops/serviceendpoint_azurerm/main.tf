resource "azuredevops_serviceendpoint_azurerm" "serviceendpoint_azurerm" {
  project_id                             = var.azure_devops_project_id
  service_endpoint_name                  = var.azure_devops_serviceconnection_azurerm_name
  service_endpoint_authentication_scheme = "ServicePrincipal"
  credentials {
    serviceprincipalid  = var.azure_devops_serviceconnection_sp_app_id
    serviceprincipalkey = var.azure_devops_serviceconnection_sp_secret
  }
  azurerm_spn_tenantid      = var.azure_devops_serviceconnection_sp_tenant_id
  azurerm_subscription_id   = var.azure_devops_serviceconnection_subscription_id
  azurerm_subscription_name = "test"
}
