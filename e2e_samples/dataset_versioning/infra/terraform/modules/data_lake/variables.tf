# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "rg_name" {
  type        = string
  description = "Name of resource group manually created before terraform init"
}

variable "location" {
  type        = string
  description = "Region where datalake will be provisioned"
}

variable "env" {
  type        = string
  description = "Environment where we're deploying datalake to"
}

variable "app_name" {
  type        = string
  description = "Unique identifier of the app"
}

variable "kv_id" {
  type        = string
  description = "Key Vault ID For Key Vault linked service."
}

variable "adf_identity_id" {
  type        = string
  description = "ID for ADF managed identity."
}
