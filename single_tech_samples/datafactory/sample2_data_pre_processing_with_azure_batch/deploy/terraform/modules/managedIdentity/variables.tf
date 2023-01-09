variable "resource_group_name" {
  description = "(Required) Specifies the name of the resource group."
  type        = string
  default     = "av-dataops-azure-int"
}

variable "location" {
  description = "(Required) Specifies the location where the AKS cluster will be deployed."
  type        = string
  default     = "Central India"
}

variable "tags" {
  description = "(Optional) Specifies the tags of the bastion host"
  default     = {}
}

variable "name_suffix" {
  description = "Suffix of Managed Identity name"
  type        = string
}
