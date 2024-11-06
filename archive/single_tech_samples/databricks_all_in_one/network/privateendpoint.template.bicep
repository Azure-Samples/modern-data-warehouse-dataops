@description('Storage Account Privatelink Resource')
param storageAccountPrivateLinkResource string

@description('Storage Account name')
param storageAccountName string

@description('Keyvault Private Link resource.')
param keyvaultPrivateLinkResource string

@description('keyvault name.')
param keyvaultName string = 'KeyVault'

@description('event hub name.')
param eventHubName string

@description('EventHub Private Link resource.')
param eventHubPrivateLinkResource string

@description('Vnet name for private link')
param vnetName string

@description('Privatelink subnet Id')
param privateLinkSubnetId string

@description('Privatelink subnet Id')
param privateLinkLocation string = resourceGroup().location

var privateDnsNameStorageDfs_var = 'privatelink.dfs.${environment().suffixes.storage}'
var privateDnsNameStorageBlob_var = 'privatelink.blob.${environment().suffixes.storage}'
var privateDnsNameStorageFile_var = 'privatelink.file.${environment().suffixes.storage}'
var adlsPrivateDnsZoneName_var = '${toLower(storageAccountName)}-dfs-Privateendpoint'
var filePrivateDnsZoneName_var = '${toLower(storageAccountName)}-file-Privateendpoint'
var blobPrivateDnsZoneName_var = '${toLower(storageAccountName)}-blob-Privateendpoint'

var privateDnsNameVault_var = 'privatelink.vaultcore.azure.net'
var keyvaultPrivateEndpointName_var = '${toLower(keyvaultName)}-Privateendpoint'

var privateDnsNameEventHub_var = 'privatelink.servicebus.windows.net'
var eventHubPrivateEndpointName_var = '${(eventHubName)}-Privateendpoint'

param AmlName string
param amlPrivateLinkResource string
var privateDnsNameAmlApi_var = 'privatelink.api.azureml.ms'
var privateDnsNameAmlNotebook_var = 'privatelink.notebooks.azure.net'
var amlPrivateEndpointName_var = '${AmlName}-Privateendpoint'

param containerRegistryName string
param crPrivateLinkResource string
var privateDnsNameCr_var = 'privatelink.azurecr.io'
var crPrivateEndpointName_var = '${containerRegistryName}-Privateendpoint'

resource storageAccountPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: adlsPrivateDnsZoneName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: adlsPrivateDnsZoneName_var
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource fileStorageAccountPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: filePrivateDnsZoneName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: filePrivateDnsZoneName_var
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            'file'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource blobStorageAccountPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: blobPrivateDnsZoneName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: blobPrivateDnsZoneName_var
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource privateDnsNameStorageDfs 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorageDfs_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    storageAccountPrivateEndpointName
  ]
}
resource privateDnsNameStorageFile 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorageFile_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    fileStorageAccountPrivateEndpointName
  ]
}
resource privateDnsNameStorageBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorageBlob_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    blobStorageAccountPrivateEndpointName
  ]
}

resource privateDnsNameStorageDfs_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorageDfs
  name: 'dfs_link_to_${toLower(vnetName)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource privateDnsNameStorageFile_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorageFile
  name: 'file_link_to_${toLower(vnetName)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource privateDnsNameStorageBob_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorageBlob
  name: 'file_link_to_${toLower(vnetName)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource storageAccountPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageAccountPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-dfs-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorageDfs.id
        }
      }
    ]
  }
}
resource storageAccountFilePrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: fileStorageAccountPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorageFile.id
        }
      }
    ]
  }
}
resource storageAccountBlobPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: blobStorageAccountPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorageBlob.id
        }
      }
    ]
  }
}
// Configure Private Link for KeyVault
resource keyvaultPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: keyvaultPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyvaultPrivateEndpointName_var
        properties: {
          privateLinkServiceId: keyvaultPrivateLinkResource
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
  tags: {}
}
resource privateDnsNameVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameVault_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    keyvaultPrivateEndpointName
  ]
}
resource privateDnsNameVault_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameVault
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource keyvaultPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: keyvaultPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsNameVault.id
        }
      }
    ]
  }
}

// Configure Private Link for Event Hub

resource eventHubPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: eventHubPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: eventHubPrivateEndpointName_var
        properties: {
          privateLinkServiceId: eventHubPrivateLinkResource
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource privateDnsNameEventHub 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameEventHub_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    eventHubPrivateEndpointName
  ]
}
resource privateDnsNameEventHub_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameEventHub
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource eventHubPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: eventHubPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-servicebus-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameEventHub.id
        }
      }
    ]
  }
}

// Configure Private Link to AML
resource amlPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: amlPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: amlPrivateEndpointName_var
        properties: {
          privateLinkServiceId: amlPrivateLinkResource
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource privatelink_api_azureml_ms 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsNameAmlApi_var
  location: 'global'
  properties: {}
}
resource privatelink_api_azureml_ms_resourceId_Microsoft_Network_virtualNetworks_parameters_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_api_azureml_ms
  name: 'privatelink_api_azureml_ms'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource privatelink_notebooks_azure_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsNameAmlNotebook_var
  location: 'global'
  properties: {}
}
resource privatelink_notebooks_azure_net_resourceId_Microsoft_Network_virtualNetworks_parameters_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_notebooks_azure_net
  name: 'privatelink_notebooks_azure_net'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource privateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: amlPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-api-azureml-ms'
        properties: {
          privateDnsZoneId: privatelink_api_azureml_ms.id
        }
      }
      {
        name: 'privatelink-notebooks-azure-net'
        properties: {
          privateDnsZoneId: privatelink_notebooks_azure_net.id
        }
      }
    ]
  }
}

// Configure Private Link for Container Registry

resource containerRegistryPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: crPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: crPrivateEndpointName_var
        properties: {
          privateLinkServiceId: crPrivateLinkResource
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}

resource privateDnsNameContainerRegistry 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameCr_var
  location: 'global'
  dependsOn: [
    containerRegistryPrivateEndpointName
  ]
}

resource privateDnsNameContainerRegistry_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameContainerRegistry
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}

resource privateDnsNameContainerRegistry_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: containerRegistryPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: privateDnsNameContainerRegistry.id
        }
      }
    ]
  }
}
