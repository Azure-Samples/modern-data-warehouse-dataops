
@description('')
param clientPcName string
var networkInterfaceName = '${clientPcName}-Iface'
var virtualMachineName  = clientPcName

@description('')
param osDiskType string = 'Premium_LRS'
@description('')
param virtualMachineSize string = 'Standard_DS1_v2'
@description('')
param patchMode string = 'AutomaticByOS'
@description('')
param vnetName string
@description('')
param adminUsername string
@description('')
param location string = resourceGroup().location
@description('')
@secure()
param adminPassword string

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'ClientDevices')

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro-g2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: patchMode
        }
      }
    }
    licenseType: 'Windows_Client'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

// output adminUsername string = adminUsername
output clientPrivateIpaddr string = reference(resourceId('Microsoft.Network/networkInterfaces', networkInterfaceName)).ipConfigurations[0].properties.privateIPAddress
