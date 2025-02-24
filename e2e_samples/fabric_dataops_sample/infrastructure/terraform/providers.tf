provider "random" {}
provider "azuread" {
  tenant_id = var.tenant_id
}

provider "fabric" {
  use_cli       = var.use_cli
  use_msi       = var.use_msi
  tenant_id     = var.tenant_id
  client_id     = var.use_msi || var.use_cli ? null : var.client_id
  client_secret = var.use_msi || var.use_cli ? null : var.client_secret
  preview       = true
}

provider "azurerm" {
  tenant_id                       = var.tenant_id
  subscription_id                 = var.subscription_id
  client_id                       = var.use_msi || var.use_cli ? null : var.client_id
  client_secret                   = var.use_msi || var.use_cli ? null : var.client_secret
  use_msi                         = var.use_msi
  use_cli                         = var.use_cli
  storage_use_azuread             = true
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/${var.git_organization_name}"
  tenant_id       = var.use_msi ? null : var.tenant_id
  client_id       = var.use_msi ? null : var.client_id
  client_secret   = var.use_msi ? null : var.client_secret
  use_msi         = var.use_msi
}
