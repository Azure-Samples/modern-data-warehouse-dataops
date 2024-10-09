@description('Azure datacentre Location to deploy the Firewall and IP Address')
param routeTableLocation string = resourceGroup().location
@description('Name of the Routing Table')
param routeTableName string

resource routeTableName_resource 'Microsoft.Network/routeTables@2020-08-01' = {
  name: routeTableName
  location: routeTableLocation
  properties: {
    disableBgpRoutePropagation: false
  }
}

output routeTblName string = routeTableName_resource.name
