param name string
param env string
param location string 
param query string
param storageAccountName string
param iotHubsName string
param streamingUnits int = 1

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' existing = {
  name: storageAccountName
}

resource iotHubs 'Microsoft.Devices/IotHubs@2022-04-30-preview' existing = {
  name: iotHubsName
}

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
        iotHubNamespace: iotHubs.name
        sharedAccessPolicyName: iotHubs.listkeys().value[0].keyName
        sharedAccessPolicyKey: iotHubs.listkeys().value[0].primaryKey
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
          {
            accountName: storageAccount.name
            accountKey: storageAccount.listKeys().keys[0].value
          }
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
  location: location
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
