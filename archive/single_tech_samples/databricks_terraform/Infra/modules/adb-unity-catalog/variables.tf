variable "region" {
  description = "Azure region"
  type        = string
}

variable "account_id" {
  description = "Azure databricks account id"
}

variable "subscription_id" {
  description = "Azure subscription id"
}

variable "aad_groups" {
  description = "List of AAD groups that you want to add to Databricks account"
  type        = list(string)
}

variable "environment" {
  description = "The environment to deploy (dev, stg, prod)"
  type        = string
}

variable "databricks_groups" {
  description = "Map of AAD group object id to Databricks group id"
  type        = map(string)
}

variable "databricks_users" {
  description = "Map of AAD user object id to Databricks user id"
  type        = map(string)
}

variable "databricks_sps" {
  description = "Map of AAD service principal object id to Databricks service principal id"
  type        = map(string)
}

variable "databricks_workspace_id" {
  description = "Azure databricks workspace id"
  type        = string
}

variable "azurerm_databricks_access_connector_id" {
  description = "Azure databricks access connector id"
  type        = string
}

variable "metastore_id" {
  description = "Azure databricks metastore id"
  type        = string
}

variable "azurerm_storage_account_unity_catalog_id" {
  description = "Azure storage account for Unity catalog"
}

variable "databricks_workspace_host_url" {
  description = "Databricks workspace host url"
  type        = string

}

variable "azure_storage_account_name" {
  description = "Azure storage account name"
  type        = string
}

data "azuread_group" "this" {
  for_each     = local.aad_groups
  display_name = each.value
}

data "azurerm_client_config" "current" {
}