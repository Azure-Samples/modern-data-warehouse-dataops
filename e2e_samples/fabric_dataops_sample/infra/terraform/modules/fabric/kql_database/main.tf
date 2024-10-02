terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-beta.3"
    }
  }
}

resource "fabric_kql_database" "kql_database" {
  display_name = var.database_name
  description  = var.database_description
  workspace_id = var.workspace_id

  configuration = merge(
    {
      database_type = var.database_type
      eventhouse_id = var.eventhouse_id
    },
    var.database_type == "Shortcut" ? {
      source_database_name = var.source_database_name
      source_cluster_uri   = var.source_cluster_uri
    } : {}
  )
}