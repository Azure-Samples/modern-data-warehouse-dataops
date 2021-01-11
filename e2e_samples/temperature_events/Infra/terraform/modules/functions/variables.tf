# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group name that the service uses"
  type        = string
}

variable "function_name" {
  description = "String value appended to the name of each function app"
  type        = string
}

variable "appservice_plan" {
  type        = string
  description = "The id of the app service plan"
}

variable "appsettings" {
  type        = map(string)
  description = "Map of app settings that will be applied across all provisioned function apps"
}

variable "resource_name" {
  description = "Name of this service"
  type        = string
}

variable "location" {
  description = "Location where azure function is provisioned to"
  type        = string
}

variable "environment" {
  description = "Environment where we're deploying azure functions to"
  type        = string
}
