variable "region" {
  default = "West US"
}

variable "environment" {
  default = "dev"
}

variable "subscription_id" {
  default = ""
}

# use your add groups here
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