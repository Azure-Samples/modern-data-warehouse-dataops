# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "rg_name" {
  type        = string
  description = "Name of resource group manually created before terraform init"
}

variable "kv_id" {
  type        = string
  description = "Key Vault ID For Key Vault linked service."
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

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "admin_user" {
  type        = string
  description = "admin user"
  default     = "ForDataOpsDemoAdmin"
}
