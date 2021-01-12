# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
}

variable "location" {
  description = "Azure Location of the service"
  type        = string
}


variable "eventhub_config" {
  type = object({
    sku               = string
    capacity          = number
    max_capacity      = number
    partition_count   = number
    message_retention = number
  })
  description = "Configuration for Eventhubs assuming all Eventhubs have exact same configuration"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of service"
  default     = "tempevt"
  type        = string
}

variable "kv_sku" {
  type        = string
  description = "SKU of the Keyvault to create"
}

variable "event_hub_names" {
  default     = ["Analytics", "Device", "OutOfBoundsTemperature", "TemperatureDevice"]
  type        = list(string)
  description = "List of string value appended to Eventhubs"
}

variable "functions_names" {
  type        = list(string)
  default     = ["TemperatureFilter", "DeviceIdFilter"]
  description = "List of string value appended to Azure Functions"
}

variable "app_insights_name" {
  type        = string
  default     = "appinsights"
  description = "Name of app insights"
}

variable "key_permissions" {
  type        = list(string)
  default     = ["get"]
  description = "List of key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey."
}

variable "appinsights_application_type" {
  description = "ype of the App Insights Application."
  default     = "web"
  type        = string
}

variable "retention" {
  type        = number
  default     = 90
  description = "Retention period for app insights"
}
