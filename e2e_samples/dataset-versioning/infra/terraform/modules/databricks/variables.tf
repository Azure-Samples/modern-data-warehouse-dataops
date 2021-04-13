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

variable "sku" {
  type        = string
  description = "Unique identifier of the app"
  default     = "premium"
}
