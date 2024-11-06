@description('')
param vnetName string
@allowed([
  'standard'
  'premium'
])
@description('')
param adbWorkspaceSkuTier string
@description('')
param publicSubnetName string = 'public-subnet'
@description('')
param privateSubnetName string = 'private-subnet'
@description('')
param disablePublicIp bool = true
@description('')
param adbWorkspaceLocation string = resourceGroup().location
@description('')
param adbWorkspaceName string
@description('')
param tagValues object = {}

var managedResourceGroupName = 'databricks-rg-${adbWorkspaceName}-${uniqueString(adbWorkspaceName, resourceGroup().id)}'
var managedResourceGroupId = '${subscription().id}/resourceGroups/${managedResourceGroupName}'
var vnetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)

resource adbWorkspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
  location: adbWorkspaceLocation
  name: adbWorkspaceName
  sku: {
    name: adbWorkspaceSkuTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
  }
  tags: tagValues
  dependsOn: []
}


output databricks_workspace_id string = adbWorkspaceName_resource.id
output databricks_workspaceUrl string = adbWorkspaceName_resource.properties.workspaceUrl
output databricks_dbfs_storage_accountName string = adbWorkspaceName_resource.properties.parameters.storageAccountName.value
