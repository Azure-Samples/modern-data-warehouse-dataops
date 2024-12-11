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
# they should exist in Azure EntraID before running the terraform 
variable "aad_groups" {
  default = ["account_unity_admin", "data_engineer", "data_analyst", "data_scientist"]
}

variable "metastore_name"{
  default = ""
}

# login https://accounts.azuredatabricks.net 
# click on the profile icon on the top right corner to get the account_id
variable "account_id" {
  description = ""
  default = ""
}