# Databricks Infrastructure as Code Template Generator

Use this prompt to generate comprehensive Infrastructure as Code (IaC) for Azure Databricks environments with Unity Catalog, following proven enterprise patterns.

---

**Prompt for GitHub Copilot:**

You are an Azure infrastructure expert specializing in Databricks and Unity Catalog deployments. Help me generate comprehensive Infrastructure as Code (Bicep templates) for an Azure Databricks environment that follows enterprise best practices based on the proven patterns from the Azure-Samples/modern-data-warehouse-dataops repository.

## My Infrastructure Requirements

**Project Name**: [Your project name - will be used in resource naming]

**Environments**: [Number and names of environments: dev, staging, prod, etc.]

**Region**: [Primary Azure region for deployment]

**Data Sources**: [Types of data sources to integrate with]

**Compliance Requirements**: [Any specific compliance, security, or governance needs]

**Network Requirements**: [VNet integration, private endpoints, network security requirements]

**Monitoring Requirements**: [Logging, alerting, and monitoring needs]

## Generate Complete Infrastructure

Please generate a comprehensive Bicep infrastructure setup including:

### 1. Main Bicep Template Structure

Create a modular main.bicep template with the following architecture:

```bicep
// main.bicep
param project string = 'myproject'
param env string = 'dev'
param location string = resourceGroup().location
param deployment_id string
param keyvault_owner_object_id string
@secure()
param sql_server_password string
param enable_monitoring bool = true
param enable_unity_catalog bool = true
param enable_private_endpoints bool = false
param databricks_sku string = 'standard'
param entra_admin_login string

// Core infrastructure modules
module databricks './modules/databricks.bicep' = {
  name: 'databricks_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    sku: databricks_sku
    enable_unity_catalog: enable_unity_catalog
    enable_private_endpoints: enable_private_endpoints
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    databricks_principal_id: databricks.outputs.databricks_managed_identity_id
    enable_private_endpoints: enable_private_endpoints
  }
}

module unity_catalog './modules/unity_catalog.bicep' = if (enable_unity_catalog) {
  name: 'unity_catalog_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    databricks_workspace_id: databricks.outputs.workspace_id
    storage_account_id: storage.outputs.data_lake_storage_id
    metastore_storage_account_id: storage.outputs.metastore_storage_id
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    keyvault_owner_object_id: keyvault_owner_object_id
    databricks_principal_id: databricks.outputs.databricks_managed_identity_id
    enable_private_endpoints: enable_private_endpoints
  }
}

module monitoring './modules/monitoring.bicep' = if (enable_monitoring) {
  name: 'monitoring_deploy_${deployment_id}'
  params: {
    project: project
    env: env
    location: location
    deployment_id: deployment_id
    databricks_workspace_id: databricks.outputs.workspace_id
  }
}

// Outputs for CI/CD pipelines
output databricks_workspace_url string = databricks.outputs.workspace_url
output databricks_workspace_id string = databricks.outputs.workspace_id
output data_lake_storage_account string = storage.outputs.data_lake_storage_account
output unity_catalog_metastore_id string = enable_unity_catalog ? unity_catalog.outputs.metastore_id : ''
output keyvault_url string = keyvault.outputs.keyvault_url
output application_insights_key string = enable_monitoring ? monitoring.outputs.application_insights_key : ''
```

### 2. Databricks Module (modules/databricks.bicep)

Generate a comprehensive Databricks workspace module including:

**Features to Include**:
- Databricks workspace with proper SKU configuration
- Managed Identity for secure authentication
- Unity Catalog enablement (if required)
- VNet integration (if required)
- Private endpoints for secure connectivity
- Workspace configuration and policies
- Integration with monitoring services

**Expected Structure**:
```bicep
param project string
param env string
param location string
param deployment_id string
param sku string = 'standard'
param enable_unity_catalog bool = true
param enable_private_endpoints bool = false
param vnet_id string = ''
param private_subnet_id string = ''
param public_subnet_id string = ''

// Managed Identity for Databricks workspace
resource databricks_managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi-${project}-databricks-${env}-${deployment_id}'
  location: location
  tags: {
    Environment: env
    Project: project
    DeploymentId: deployment_id
  }
}

// Databricks workspace
resource databricks_workspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: 'dbw-${project}-${env}-${deployment_id}'
  location: location
  sku: {
    name: sku
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', 'databricks-rg-${project}-${env}-${deployment_id}')
    parameters: enable_private_endpoints ? {
      customVirtualNetworkId: {
        value: vnet_id
      }
      customPrivateSubnetName: {
        value: last(split(private_subnet_id, '/'))
      }
      customPublicSubnetName: {
        value: last(split(public_subnet_id, '/'))
      }
      enableNoPublicIp: {
        value: true
      }
    } : {}
    publicNetworkAccess: enable_private_endpoints ? 'Disabled' : 'Enabled'
    requiredNsgRules: enable_private_endpoints ? 'NoAzureDatabricksRules' : 'AllRules'
  }
  tags: {
    Environment: env
    Project: project
    DeploymentId: deployment_id
  }
}

// Unity Catalog enablement
resource unity_catalog_assignment 'Microsoft.Databricks/workspaces/metastoreAssignments@2023-02-01' = if (enable_unity_catalog) {
  parent: databricks_workspace
  name: 'default'
  properties: {
    metastoreId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Databricks/metastores/metastore-${project}-${env}-${deployment_id}'
  }
}

output workspace_id string = databricks_workspace.id
output workspace_url string = 'https://${databricks_workspace.properties.workspaceUrl}'
output databricks_managed_identity_id string = databricks_managed_identity.id
output databricks_managed_identity_principal_id string = databricks_managed_identity.properties.principalId
```

### 3. Storage Module (modules/storage.bicep)

Generate storage infrastructure including:

**Components**:
- ADLS Gen2 for data lake (bronze, silver, gold containers)
- ADLS Gen2 for Unity Catalog metastore storage
- Managed Identity integration
- Private endpoints (if required)
- Lifecycle management policies
- Access control configuration

**Expected Implementation**:
```bicep
param project string
param env string
param location string
param deployment_id string
param databricks_principal_id string
param enable_private_endpoints bool = false

// Data Lake Storage Account
resource data_lake_storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${project}${env}${deployment_id}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: enable_private_endpoints ? 'Disabled' : 'Enabled'
    networkAcls: enable_private_endpoints ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    } : {
      defaultAction: 'Allow'
    }
  }
  tags: {
    Environment: env
    Project: project
    DeploymentId: deployment_id
    Purpose: 'DataLake'
  }
}

// Data Lake Containers for Medallion Architecture
resource bronze_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${data_lake_storage.name}/default/bronze'
  properties: {
    publicAccess: 'None'
  }
}

resource silver_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${data_lake_storage.name}/default/silver'
  properties: {
    publicAccess: 'None'
  }
}

resource gold_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${data_lake_storage.name}/default/gold'
  properties: {
    publicAccess: 'None'
  }
}

// Unity Catalog Metastore Storage
resource metastore_storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${project}cat${env}${deployment_id}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: enable_private_endpoints ? 'Disabled' : 'Enabled'
  }
  tags: {
    Environment: env
    Project: project
    DeploymentId: deployment_id
    Purpose: 'UnityCatalogMetastore'
  }
}

resource metastore_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${metastore_storage.name}/default/metastore'
  properties: {
    publicAccess: 'None'
  }
}

// Role assignments for Databricks managed identity
resource databricks_storage_contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(data_lake_storage.id, databricks_principal_id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: data_lake_storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: databricks_principal_id
    principalType: 'ServicePrincipal'
  }
}

// Private endpoints (if enabled)
resource storage_private_endpoint 'Microsoft.Network/privateEndpoints@2023-02-01' = if (enable_private_endpoints) {
  name: 'pep-${data_lake_storage.name}-blob'
  location: location
  properties: {
    subnet: {
      id: vnet_private_endpoint_subnet_id // Passed as parameter
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: data_lake_storage.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

output data_lake_storage_id string = data_lake_storage.id
output data_lake_storage_account string = data_lake_storage.name
output metastore_storage_id string = metastore_storage.id
output metastore_storage_account string = metastore_storage.name
```

### 4. Unity Catalog Module (modules/unity_catalog.bicep)

Generate Unity Catalog infrastructure including:

**Components**:
- Regional metastore setup
- Storage credentials with managed identity
- External locations for data access
- Catalog and schema creation
- Permission configurations

### 5. Key Vault Module (modules/keyvault.bicep)

Generate secure secrets management including:

**Components**:
- Key Vault with appropriate access policies
- Databricks secret scope integration
- Service principal secrets storage
- Private endpoint configuration
- Audit logging enablement

### 6. Monitoring Module (modules/monitoring.bicep)

Generate comprehensive monitoring including:

**Components**:
- Application Insights for telemetry
- Log Analytics Workspace for centralized logging
- Databricks diagnostic settings
- Custom dashboards and alerts
- Cost monitoring and optimization alerts

### 7. Environment Parameter Files

Generate parameter files for each environment:

**main.parameters.dev.json**:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "project": {
      "value": "myproject"
    },
    "env": {
      "value": "dev"
    },
    "deployment_id": {
      "value": "001"
    },
    "enable_monitoring": {
      "value": true
    },
    "enable_unity_catalog": {
      "value": true
    },
    "enable_private_endpoints": {
      "value": false
    },
    "databricks_sku": {
      "value": "standard"
    }
  }
}
```

### 8. Deployment Scripts

Generate deployment automation scripts:

**deploy.sh**:
```bash
#!/bin/bash
set -e

# Configuration
PROJECT_NAME="myproject"
LOCATION="eastus2"
ENVIRONMENTS=("dev" "staging" "prod")

# Function to deploy environment
deploy_environment() {
    local env=$1
    local rg_name="rg-${PROJECT_NAME}-${env}"
    
    echo "Deploying to environment: $env"
    
    # Create resource group
    az group create --name $rg_name --location $LOCATION
    
    # Deploy infrastructure
    az deployment group create \
        --resource-group $rg_name \
        --template-file infrastructure/main.bicep \
        --parameters @infrastructure/main.parameters.${env}.json \
        --parameters keyvault_owner_object_id=$(az ad signed-in-user show --query id -o tsv)
}

# Deploy to each environment
for env in "${ENVIRONMENTS[@]}"; do
    deploy_environment $env
done
```

## Customization Questions

To generate the most appropriate infrastructure:

1. **Networking**: Do you need VNet integration, private endpoints, or specific network security requirements?

2. **Unity Catalog**: Do you need multi-region Unity Catalog setup or specific governance requirements?

3. **Monitoring**: What specific metrics, alerts, and dashboards do you need for operational visibility?

4. **Security**: What compliance requirements (SOC2, HIPAA, etc.) or security controls need to be implemented?

5. **Scaling**: What are your expected workload patterns and scaling requirements?

6. **Integration**: Do you need integration with existing Azure services, on-premises systems, or third-party tools?

Based on your answers, I'll generate customized Bicep templates, parameter files, and deployment scripts that follow proven enterprise patterns while meeting your specific requirements.

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Provide your specific infrastructure requirements
3. Review and customize the generated Bicep templates
4. Update parameter files for your environments
5. Execute the deployment scripts to provision your infrastructure
