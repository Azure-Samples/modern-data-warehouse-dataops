terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.4"
    }
  }
}

resource "fabric_workspace_git" "git_integration" {
  count = var.enable ? 1 : 0
  workspace_id            = var.workspace_id
  initialization_strategy = var.initialization_strategy
  git_provider_details = {
    git_provider_type = var.git_provider_type
    organization_name = var.organization_name
    project_name      = var.project_name
    repository_name   = var.repository_name
    branch_name       = var.branch_name
    directory_name    = var.directory_name
  }
}