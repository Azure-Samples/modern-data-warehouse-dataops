param name string
param env string
param query string

module iothubs './iothubs.bicep' = {
  name: 'iothubs'
  params: {
    name: name
    env: env
  }
}

module containers './containers.bicep' = {
  name: 'containers'
  params: {
    name: name
    env: env
  }
}

module streaming_jobs './streamingjobs.bicep' = {
  name: 'streaming_jobs'
  params: {
    name: name
    env: env
    query: query
    sharedAccessPolicy: iothubs.outputs.sharedAccessPolicy
    storageAccount: containers.outputs.account
  }
}
