# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group name that the service uses"
  type        = string
}

variable "resource_name" {
  description = "Name of this service"
  type        = string
}

variable "location" {
  description = "Location where eventhub is provisioned to"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

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
