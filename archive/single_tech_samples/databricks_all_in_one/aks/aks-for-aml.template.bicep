param amlWorkspaceName string
param sslLeafName string
param aksAgentCount int
param aksAgentVMSize string
param aksAmlComputeName string
param aksSubnetId string
param identity string

resource amlAks 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: '${amlWorkspaceName}/${aksAmlComputeName}'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities:{
    '${identity}' : {}
    }
  }
  properties:{
    computeType: 'AKS'
    computeLocation: resourceGroup().location
    description: 'AKS cluster to provide inference REST endpoint'
    properties: {
      loadBalancerType:'PublicIp'
      agentCount: aksAgentCount
      agentVmSize:aksAgentVMSize
      aksNetworkingConfiguration:{
        dnsServiceIP:'10.179.128.10'
        serviceCidr:'192.168.0.0/24'
        dockerBridgeCidr: '172.17.0.1/16'
        subnetId: aksSubnetId
      }
      clusterPurpose:'FastProd'
      sslConfiguration:{
        leafDomainLabel: sslLeafName
        status: 'Auto'       
      }
    }
  }
}
