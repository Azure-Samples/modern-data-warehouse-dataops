variable "databricks_workspace_name" {
  description = "Azure databricks workspace name"
}
variable "environment" {
  description = "The environment to deploy (dev, stg, prod)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription id"
}

variable "resource_group" {
  description = "Azure resource group"
}

variable "region" {
  description = "Azure region"
  type        = string

}
variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
}
variable "account_id" {
  description = "Azure databricks account id"
}
variable "prefix" {
  description = "Prefix to be used with resouce names"
}

variable "databricks_workspace_host_url" {
  description = "Databricks workspace host url"
}

variable "databricks_workspace_id" {
  description = "Databricks workspace id"
}

variable "metastore_name" {
  description = "Name of the metastore"
}

data "azurerm_resource_group" "this" {
  name = var.resource_group
}

data "azurerm_databricks_workspace" "this" {
  name                = var.databricks_workspace_name
  resource_group_name = var.resource_group
}

// Read group members of given groups from AzureAD every time Terraform is started
data "azuread_group" "this" {
  for_each     = local.aad_groups
  display_name = each.value
}

// Extract information about real users
data "azuread_users" "users" {
  ignore_missing = true
  object_ids     = local.all_members
}

// Extract information about service prinicpals users
data "azuread_service_principals" "spns" {
  object_ids = toset(setsubtract(local.all_members, data.azuread_users.users.object_ids))
}

# Extract information about real account admins users
data "azuread_users" "account_admin_users" {
  ignore_missing = true
  object_ids     = local.account_admin_members
}