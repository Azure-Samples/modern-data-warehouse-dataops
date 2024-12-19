variable "principal_id" {
  description = "The object ID of the principal (user, group, or service principal) to assign the role to."
  type        = string
}

variable "role_definition_name" {
  description = "The name of the role definition to assign."
  type        = string
}

variable "scope" {
  description = "The scope at which the role assignment applies."
  type        = string
}
