# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "rg_name" {
  type        = string
  description = "Name of resource group manually created before terraform init"
}

variable "app_name" {
  type        = string
  description = "Unique identifier of the app"
}

variable "env" {
  type        = string
  description = "Environment where we're deploying resources to"
}

variable "location" {
  type        = string
  description = "Location of keyvault"
}

variable "client_config_current" {
  type = object({
    tenant_id = string
    object_id = string
  })
}

variable "adf_identity_id" {
  type        = string
  description = "ID for ADF managed identity."
}
