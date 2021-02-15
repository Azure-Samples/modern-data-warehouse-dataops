# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "environment" {
  type = string

  description = "The name of the environment we're deploying to"
}

variable "location" {
  type = string

  description = "Azure Location of the service"
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

variable "kv_sku" {
  type        = string
  description = "SKU of the Keyvault to create"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  description = "The name of service"
}

variable "event_hub_names" {
  type        = list(string)
  description = "List of string value appended to Eventhubs"
  default     = ["Analytics", "Ingest", "OutOfBoundsTemperature", "FilteredDevices"]
}

variable "functions_names" {
  type        = list(string)
  description = "List of string value appended to Azure Functions"
  default     = ["TemperatureFilter", "DeviceIdFilter"]

}

variable "app_insights_name" {
  type        = string
  description = "Name of App Insights"
  default     = "appinsights"
}

variable "key_permissions" {
  type        = list(string)
  description = "List of key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey."
  default     = ["get"]
}

variable "appinsights_application_type" {
  type        = string
  description = "Type of the App Insights Application."
  default     = "web"
}

variable "retention" {
  type        = number
  description = "Retention period for App Insights"
  default     = 90
}

variable "set_key_permissions" {
  type        = list(string)
  description = "List of key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey"
  default     = ["set", "get", "delete", "purge"]
}
