# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "eventhub_name" {
  type        = string
  description = "Name of eventhub"
}

variable "eventhub_connection_string" {
  type        = string
  description = "Connection string for eventhub"
}

variable "keyvault_id" {
  type        = string
  description = "Specifies the name of the Key Vault resource."
}
