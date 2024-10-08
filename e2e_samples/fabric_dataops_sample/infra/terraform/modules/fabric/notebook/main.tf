terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_notebook" "notebook" {
  display_name = var.notebook_name
  description  = var.notebook_description
  workspace_id = var.workspace_id
  definition = {
    "notebook-content.ipynb" = {
      source = var.notebook_definition_path
      tokens = var.tokens
    }
  }
  definition_update_enabled = var.definition_update_enabled
}
