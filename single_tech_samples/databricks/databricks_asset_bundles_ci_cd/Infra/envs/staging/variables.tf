variable "region" {
  default = "East US"
}

variable "environment" {
  default = "stg"
}

variable "subscription_id" {
  default = ""
}

variable "aad_groups" {
  default = ["account_unity_admin", "data_engineer", "data_analyst", "data_scientist"]
}

variable "metastore_name"{
  default = ""
}

# Once databricks workspace has been create
# This value can be added
variable "account_id" {
  description = ""
  default = ""
}