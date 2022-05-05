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
  description = "Azure Location of the service"
}

variable "app_name" {
  type        = string
  description = "Unique identifier of the app"
}

variable "env" {
  type        = string
  description = "Environment where we're deploying resources to"
}

variable "configure_factory_repo" {
  type        = bool
  description = "Flag sets whether factory repository connection with be configured"
  default     = false
}
