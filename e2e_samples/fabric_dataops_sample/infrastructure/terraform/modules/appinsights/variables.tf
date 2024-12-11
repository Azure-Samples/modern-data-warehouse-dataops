variable "name" {
  description = "The name of the Application Insights component"
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "workspace_id" {
  description = "The id of a log analytics workspace resource"
  type        = string
}

variable "application_type" {
  description = "The type of Application Insights to create"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}
