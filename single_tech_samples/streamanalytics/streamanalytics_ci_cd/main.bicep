param name string
param env string
param location string = resourceGroup().location
param query string

// Partner attribution for telemetry tracking
resource attribution 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-acce1e78-XXXX-XXXX-XXXX-XXXXXXXXXXXXX'  // Replace with unique GUID for streamanalytics_ci_cd sample
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module iothubs './iothubs.bicep' = {
  name: 'iothubs'
  params: {
    name: name
    env: env
    location: location
  }
}

module containers './containers.bicep' = {
  name: 'containers'
  params: {
    name: name
    env: env
    location: location
  }
}

module streaming_jobs './streamingjobs.bicep' = {
  name: 'streaming_jobs'
  params: {
    name: name
    env: env
    location: location
    query: query    
    storageAccountName: containers.outputs.storageAccountName
    iotHubsName: iothubs.outputs.iotHubsName
  }  
}
