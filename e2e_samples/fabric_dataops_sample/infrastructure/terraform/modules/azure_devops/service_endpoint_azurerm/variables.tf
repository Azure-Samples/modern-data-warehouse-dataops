variable "project_id" {
  description = "Azure DevOps project ID"
  type        = string
}

variable "service_endpoint_name" {
  description = "ARM service endpoint name"
  type        = string
}

variable "service_endpoint_authentication_scheme" {
  description = "ARM service endpoint type. Possible values are 'ServicePrincipal', 'ManagedServiceIdentity' or 'WorkloadIdentityFederation'"
  type        = string
  default     = "ManagedServiceIdentity"
}

variable "service_principal_id" {
  description = "The service principal application ID (required if using 'ServicePrincipal' authentication scheme)"
  type        = string
  default     = null
}

variable "service_principal_key" {
  description = "The service principal secret (required if using 'ServicePrincipal' authentication scheme)"
  type        = string
  sensitive   = true
  default     = null
}

variable "tenant_id" {
  description = "The tenant ID of the service principal"
  type        = string
}

variable "subscription_id" {
  description = "ARM subscription ID"
  type        = string
}

variable "subscription_name" {
  description = "ARM subscription name"
  type        = string
}
