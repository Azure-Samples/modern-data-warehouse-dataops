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
  description = "Region where data factory will be provisioned"
}

variable "env" {
  type        = string
  description = "Environment where we're deploying data factory to"
}

variable "app_name" {
  type        = string
  description = "Unique identifier of the app"
}

variable "kv_id" {
  type        = string
  description = "Key Vault ID For Key Vault linked service."
}

variable "kv_name" {
  type        = string
  description = "Key Vault Name For Key Vault linked service."
}
