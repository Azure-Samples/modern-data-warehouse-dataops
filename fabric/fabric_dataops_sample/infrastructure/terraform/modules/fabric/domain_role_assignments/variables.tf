variable "domain_id" {
  description = "Microsoft Fabric domain ID"
  type        = string
}

variable "role" {
  description = "Fabric Domain role name"
  type        = string

  validation {
    condition     = contains(["Admins", "Contributors"], var.role)
    error_message = "The Domain role must be one of: Admins, Contributors."
  }
}

variable "principals" {
  description = "Microsoft Fabric domain role principals (list of objects)"
  type = list(object({
    id   = string,
    type = string
  }))
}
