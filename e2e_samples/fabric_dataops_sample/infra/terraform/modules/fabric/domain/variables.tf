variable "domain_name" {
  description = "Microsoft Fabric domain display name"
  type        = string
}

variable "domain_description" {
  description = "Microsoft Fabric domain description"
  type        = string
  default     = null
}

variable "parent_domain_id" {
  description = "Parent Fabric domain Id to create a subdomain"
  type        = string
  default     = null
}

variable "contributors_scope" {
  description = "Contributors scope for the domain"
  type        = string
  default     = null
}
