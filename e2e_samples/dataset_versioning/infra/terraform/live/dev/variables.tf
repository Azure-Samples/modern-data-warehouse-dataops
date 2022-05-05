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
  validation {
    condition     = length(var.app_name) > 3 && length(var.app_name) <= 18
    error_message = "'app_name' length should be between 3 to 18."
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "location" {
  type        = string
  description = "Azure Location of the service"
  default     = "eastus"
}

variable "env" {
  type        = string
  description = "Environment where we're provisioning to"
  default     = "dev"
}
