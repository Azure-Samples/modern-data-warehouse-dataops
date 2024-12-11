variable "workspace_id" {
  description = "Microsoft Fabric workspace id"
  type        = string
}

variable "principal_id" {
  description = "The principal Id for the role assignment"
  type        = string
}

variable "principal_type" {
  description = "The principal type for the role assignment"
  type        = string
}

variable "role" {
  description = "The workspace role to be assigned to the principal"
  type        = string
}
