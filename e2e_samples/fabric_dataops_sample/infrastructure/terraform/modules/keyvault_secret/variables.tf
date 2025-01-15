variable "enable" {
  type        = bool
  description = "whether this module should do anything at all"
  default     = false
}

variable "name" {
  description = "The name of the Key Vault Secret. Changing this forces a new resource to be created."
  type        = string
}

variable "value" {
  description = "The value of the Key Vault Secret. Changing this will create a new version of the Key Vault Secret."
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault where the Secret should be created. Changing this forces a new resource to be created."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
}

variable "expiration_date" {
  description = "(Optional) The expiration date of the Key Vault Secret."
  type        = string
  default     = "2099-12-31T23:59:59Z"
}

variable "content_type" {
  description = "(Optional) The content type of the Key Vault Secret."
  type        = string
  default     = "Secret"
}
