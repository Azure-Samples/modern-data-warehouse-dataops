locals {
  aad_groups  = toset(var.aad_groups)
  
  all_members = toset(flatten([for group in values(data.azuread_group.this) : group.members]))
  
  all_users = {
    for user in data.azuread_users.users.users : user.object_id => user
  }
  
  all_spns = {
    for sp in data.azuread_service_principals.spns.service_principals : sp.object_id => sp
  }
  
  account_admin_members = toset(flatten([for group in values(data.azuread_group.this) : [group.display_name == "account_unity_admin" ? group.members : []]]))
  
  all_account_admin_users = {
    for user in data.azuread_users.account_admin_users.users : user.object_id => user
  }

  metastore_id = length(data.databricks_metastore.existing.id) > 0 ? data.databricks_metastore.existing.id : databricks_metastore.this[0].id
}
