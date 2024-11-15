// param amlWorkspaceName string
param aksAgentCount int
param aksAgentVMSize string
param aksSubnetId string
param dnsPrefix string
param maxPods int = 110
@description('The name of the Managed Cluster resource.')
param clusterName string
param location string = resourceGroup().location

resource AksCluster 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned' // Require this to be systemassigned
  }
  properties: {
    dnsPrefix: dnsPrefix
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
      dnsServiceIP: '10.0.0.10' //default service CIDR is 10.0.0.0/16
      dockerBridgeCidr: '172.17.0.1/16'
      podCidr: '10.244.0.0/16'
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: aksAgentCount
        vmSize: aksAgentVMSize
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        osType: 'Linux'
        vnetSubnetID: aksSubnetId
        maxPods: maxPods
      }
    ]
    nodeResourceGroup: 'MC_${resourceGroup().name}_${clusterName}_${location}'
  }
}

output aksClusterResourceId string = AksCluster.id
output kubeletidentity string = AksCluster.properties.identityProfile.kubeletidentity.objectId
