resource "azuredevops_variable_group" "vargroup" {
  project_id   = var.azure_devops_project_id
  name         = var.azure_devops_variable_group_name
  allow_access = true

  dynamic "variable" {
    for_each = var.azure_devops_variable_group_variables
    content {
      name  = variable.key
      value = variable.value
    }
  }
}
