param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string

// param account_name string = ''
// param repository_name string = ''
// param collaboration_branch string = 'main'
// param root_folder string = '/e2e_samples/parking_sensors/adf'

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${project}-adf-${env}-${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Data Factory'
    Environment: env
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = if (env == 'dev') {
//   name: adf_name
//   location: location
//   tags: {
//     DisplayName: 'Data Factory'
//     Environment: env
//   }
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     repoConfiguration: {
//       accountName: account_name
//       repositoryName: repository_name
//       collaborationBranch: collaboration_branch
//       rootFolder: root_folder
//       type: 'FactoryGitHubConfiguration'
//     }
//   }
// }


output datafactory_principal_id string = datafactory.identity.principalId
output datafactory_name string = datafactory.name
