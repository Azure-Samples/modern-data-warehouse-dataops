terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "1.1.0"
    }
  }
}
