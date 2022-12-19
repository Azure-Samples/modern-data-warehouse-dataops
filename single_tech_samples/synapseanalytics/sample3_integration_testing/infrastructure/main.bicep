param project string = 'mdwdo'
param env string = 'dev'
param location string = resourceGroup().location
param deployment_id string
param keyvault_owner_object_id string
@secure()
param synapse_sqlpool_admin_password string

module storage './modules/storage.bicep' = {
  name: 'storage_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
  }
}

module synapse './modules/synapse.bicep' = {
  name: 'synapse_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    synapse_sqlpool_admin_password: synapse_sqlpool_admin_password
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    keyvault_owner_object_id: keyvault_owner_object_id
  }
}

output storage_account_name string = storage.outputs.storage_account_name
output keyvault_name string = keyvault.outputs.keyvault_name
output keyvault_resource_id string = keyvault.outputs.keyvault_resource_id
output synapse_output_spark_pool_name string = synapse.outputs.synapseBigdataPoolName
output synapse_sql_pool_output object = synapse.outputs.synapse_sql_pool_output
output synapseworskspace_name string = synapse.outputs.synapseWorkspaceName
