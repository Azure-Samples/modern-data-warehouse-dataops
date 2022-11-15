param name string
param env string
param location string = resourceGroup().location
param query string


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
