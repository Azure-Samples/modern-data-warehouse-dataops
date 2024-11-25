@description('The name of the existing network security group to create.')
param securityGroupName string

@description('The name of the virtual network to create.')
param spokeVnetName string

@description('The name of the virtual network to create.')
param hubVnetName string

@description('The name of the private subnet to create.')
param privateSubnetName string = 'private-subnet'

@description('The name of the private subnet to create.')
param privatelinkSubnetName string = 'privatelink-subnet'

@description('The name of the public subnet to create.')
param publicSubnetName string = 'public-subnet'

@description('The name of the firewall subnet to create.')
param firewallSubnetName string = 'AzureFirewallSubnet'

@description('Name of the Routing Table')
param routeTableName string

@description('Location for all resources.')
param vnetLocation string = resourceGroup().location

@description('Cidr range for the spoke vnet.')
param spokeVnetCidr string

@description('Cidr range for the hub vnet.')
param hubVnetCidr string

@description('Cidr range for the private subnet.')
param privateSubnetCidr string

@description('Cidr range for the public subnet.')
param publicSubnetCidr string

@description('Cidr range for the firewall subnet.')
param firewallSubnetCidr string

@description('Cidr range for the private link subnet..')
param privatelinkSubnetCidr string

@description('The name of the private subnet to create.')
param aksSubnetName string = 'aks-subnet'
@description('Cidr range for the AKS subnet..')
param AksSubnetCidr string

param clinetDevicesSubnetCidr string

var securityGroupId = resourceId('Microsoft.Network/networkSecurityGroups', securityGroupName)

var serviceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: [
      resourceGroup().location
    ]
  }
  {
    service: 'Microsoft.ContainerRegistry'
    locations: [
      resourceGroup().location
    ]
  }
  {
    service: 'Microsoft.KeyVault'
    locations: [
      resourceGroup().location
    ]
  }
]

resource hubVnetName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: hubVnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetCidr
      ]
    }
    subnets: [
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetCidr
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'ClientDevices'
        properties: {
          addressPrefix: clinetDevicesSubnetCidr
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource hubVnetName_Peer_HubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: hubVnetName_resource
  name: 'Peer-HubSpoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetName_resource.id
    }
  }
}

resource spokeVnetName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  location: vnetLocation
  name: spokeVnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetCidr
      ]
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: publicSubnetCidr
          networkSecurityGroup: {
            id: securityGroupId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
          serviceEndpoints: serviceEndpoints
          delegations: [
            {
              name: 'databricks-del-public'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: privateSubnetName
        properties: {
          addressPrefix: privateSubnetCidr
          networkSecurityGroup: {
            id: securityGroupId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', routeTableName)
          }
          delegations: [
            {
              name: 'databricks-del-private'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: privatelinkSubnetName
        properties: {
          addressPrefix: privatelinkSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: serviceEndpoints
        }
      }
      {
        name: aksSubnetName
        properties: {
          addressPrefix: AksSubnetCidr
          serviceEndpoints:serviceEndpoints
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource spokeVnetName_Peer_SpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: spokeVnetName_resource
  name: 'Peer-SpokeHub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetName_resource.id
    }
  }
}

// output spoke_vnet_id string = spokeVnetName_resource.id
output privatelinksubnet_id string = resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetName, privatelinkSubnetName)
// output spoke_vnet_name string= spokeVnetName
output databricksPublicSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetName, publicSubnetName)

output spokeVnetName string = spokeVnetName

output hubVnetName string = hubVnetName

output aksSubnet_id string = resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetName, aksSubnetName)

output spokeVnetId string = spokeVnetName_resource.id
