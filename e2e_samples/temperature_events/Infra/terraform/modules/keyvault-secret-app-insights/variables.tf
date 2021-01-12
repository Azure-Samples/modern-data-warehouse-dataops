# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "instrumentation_key_value" {
  type        = string
  description = "Instrumentation key for app insights"
}

variable "keyvault_id" {
  type        = string
  description = "Specifies the name of the Key Vault resource."
}

variable "instrumentation_key_name" {
  type        = string
  description = "Name of instrumentation key name"
}
