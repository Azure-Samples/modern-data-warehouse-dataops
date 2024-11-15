terraform {
  required_version = ">= 1.9.8"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}