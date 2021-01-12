# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  type = string

  description = "Resource group name that the service uses"
}

variable "function_name" {
  type = string

  description = "String value appended to the name of each function app"
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
  type = string

  description = "Name of this service"
}

variable "location" {
  type = string

  description = "Location where azure function is provisioned to"
}

variable "environment" {
  type = string

  description = "Environment where we're deploying azure functions to"
}
