param project string = 'sintech'
param location string = resourceGroup().location
param deployment_id string

module storage './modules/storage.bicep' = {
  name: 'storage_deploy_${deployment_id}'
  params: {
    project: project
    location: location
    deployment_id: deployment_id
  }
}

module synapse './modules/synapse.bicep' = {
  name: 'synapse_deploy_${deployment_id}'
  params: {
    project: project
    location: location
    deployment_id: deployment_id
  }
}

output storage_account_name string = storage.outputs.storage_account_name
output synapseworskspace_name string = synapse.outputs.synapseWorkspaceName
output synapse_output_spark_pool_name string = synapse.outputs.synapseSparkPoolName
