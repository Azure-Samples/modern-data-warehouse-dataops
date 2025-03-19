terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 1.8.0"
    }
  }
}
