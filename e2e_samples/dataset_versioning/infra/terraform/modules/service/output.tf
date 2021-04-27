output "arm_deploy_script" {
  value       = "az deployment group create --name arm_deploy --resource-group ${data.azurerm_resource_group.rg.name} --template-file ./arm_template/arm_template.json --parameters factoryName='${module.azure_data_factory.adf_name}' KeyVault_properties_typeProperties_baseUrl='${module.keyvault.kv_uri}' AzureBlobFS_properties_typeProperties_serviceEndpoint='${module.data_lake.storage_endpoint}'"
  description = "Azure Data Factory ARM template deployment script"
}
