param name string
param env string
param query string
param sharedAccessPolicy object
param storageAccount object
param streamingUnits int = 1

var serialization = {
  type: 'Json'
  properties: {
    encoding: 'UTF8'
  }
}

var input = {
  name: 'iothub'
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.Devices/IotHubs'
      properties: {
        iotHubNamespace: 'iot-${name}-${env}'
        sharedAccessPolicyName: sharedAccessPolicy.name
        sharedAccessPolicyKey: sharedAccessPolicy.key
        consumerGroupName: '$Default'
        endpoint: 'messages/events'
      }
    }
    serialization: serialization
  }
}

var output = {
  name: 'bloboutput'
  properties: {
    datasource: {
      type: 'Microsoft.Storage/Blob'
      properties: {
        storageAccounts: [
          storageAccount
        ]
        container: 'bloboutput'        
        pathPattern: '{date}/{datetime:HH}.{datetime:mm}.{datetime:ss}'
        dateFormat: 'yyyy/MM/dd'
      }
    }
    serialization: serialization
  }
}

var transformation = {
  name: 'Transformation'
  properties: {
    streamingUnits: streamingUnits
    query: query
  }
}

resource asa_tech_sample_job 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: 'asa-${name}-${env}'
  location: resourceGroup().location  
  properties: {
    compatibilityLevel: '1.2'
    outputStartMode: 'JobStartTime'
    sku: {
      name: 'Standard'
    }
    outputErrorPolicy: 'Stop'
    dataLocale: 'en-US'
    inputs: [
      input
    ]
    outputs: [
      output
    ]
    transformation: transformation
  }
}
