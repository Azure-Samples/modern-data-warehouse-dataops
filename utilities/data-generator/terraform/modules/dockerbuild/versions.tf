terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
}
