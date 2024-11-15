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