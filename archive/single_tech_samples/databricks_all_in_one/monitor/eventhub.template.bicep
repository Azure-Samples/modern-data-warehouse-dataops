@description('Name for the Event Hub cluster.')
param namespaceName string

@description('Name for the Event Hub to be created in the Event Hub namespace within the Event Hub cluster.')
param eventHubName string = namespaceName

@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

@description('')
param eHRuleName string = 'rule'

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  parent: namespaceName_resource
  name: eventHubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
  dependsOn: [
    namespaceName_resource
  ]
}

resource namespaceName_rule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  name: '${namespaceName}/${eventHubName}/${eHRuleName}'
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
  dependsOn: [
    namespaceName_eventHubName
  ]
}

var keysObj = listKeys(resourceId('Microsoft.EventHub/namespaces/eventhubs/authorizationRules', namespaceName, eventHubName, eHRuleName), '2021-01-01-preview')

output eHNamespaceId string = namespaceName_resource.id
output eHubNameId string = namespaceName_eventHubName.id
output eHAuthRulesId string = namespaceName_rule.id
// output eHObjName object = keysObj
output eHPConnString string = keysObj.primaryConnectionString
output eHName string = eventHubName
