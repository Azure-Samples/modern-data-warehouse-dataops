# Fabric CI/CD Pipeline Implementation Guide

This guide provides comprehensive instructions for implementing enterprise-grade CI/CD pipelines for Microsoft Fabric projects, based on proven patterns from production deployments.

## Pipeline Architecture Overview

### Continuous Integration (CI) Pipelines

#### 1. QA Pipeline (Pull Request Validation)
**Trigger**: Pull requests to main/develop branch
**Purpose**: Validate changes before merge

**Key Steps**:
- Code quality checks (linting, formatting)
- Python unit test execution
- Fabric configuration validation
- Infrastructure plan validation (Terraform plan)
- Ephemeral workspace creation and testing
- Security scanning and compliance checks

**Artifacts Generated**:
- Test results and coverage reports
- Code quality analysis reports
- Infrastructure change plans
- Security scan reports

#### 2. Build Artifacts Pipeline
**Trigger**: Merge to main/develop branch
**Purpose**: Prepare deployment artifacts

**Key Steps**:
- Source code compilation and packaging
- Terraform artifact preparation
- Notebook export and validation
- Configuration file generation
- Deployment package creation
- Artifact publishing to Azure DevOps

**Artifacts Generated**:
- Deployment packages
- Infrastructure templates
- Configuration files
- Release notes

#### 3. QA Cleanup Pipeline
**Trigger**: Pull request closure
**Purpose**: Clean up ephemeral resources

**Key Steps**:
- Ephemeral workspace deletion
- Temporary resource cleanup
- Test data purging
- Cost optimization

### Continuous Deployment (CD) Pipeline

#### Release Deploy Pipeline
**Trigger**: Manual or scheduled
**Purpose**: Deploy to target environments

**Deployment Stages**:
1. **Development** (Automatic)
2. **Integration/Staging** (Automatic with quality gates)
3. **Production** (Manual approval required)

**Per-Stage Activities**:
- Infrastructure deployment (Terraform apply)
- Fabric workspace configuration
- Data pipeline deployment
- Configuration updates
- Smoke tests execution
- Deployment verification

## Implementation Patterns

### Variable Group Structure

Create environment-specific variable groups following this pattern:

```yaml
# Variable Group: vg-{project-name}-{environment}
vg-fabricproject-dev:
  # Azure Resources
  AZURE_SUBSCRIPTION_ID: "subscription-guid"
  AZURE_RESOURCE_GROUP: "rg-fabricproject-dev"
  AZURE_LOCATION: "eastus"
  
  # Storage Configuration
  AZURE_STORAGE_ACCOUNT: "stfabricprojectdev"
  AZURE_STORAGE_CONTAINER: "data"
  
  # Fabric Configuration
  FABRIC_WORKSPACE_ID: "workspace-guid"
  FABRIC_WORKSPACE_NAME: "ws-fabricproject-dev"
  FABRIC_CAPACITY_ID: "capacity-guid"
  
  # Security
  AZURE_KEY_VAULT_URL: "https://kv-fabricproject-dev.vault.azure.net/"
  AZURE_CLIENT_ID: "service-principal-guid"
  
  # Monitoring
  APPLICATION_INSIGHTS_KEY: "instrumentation-key"
  LOG_ANALYTICS_WORKSPACE_ID: "workspace-guid"
```

### Service Connection Configuration

#### Azure Resource Manager Connection
```yaml
# Service Connection: sc-fabricproject-{environment}
connectionType: AzureRM
authenticationType: ServicePrincipal
subscriptionId: $(AZURE_SUBSCRIPTION_ID)
servicePrincipalId: $(AZURE_CLIENT_ID)
```

#### Fabric API Connection
```yaml
# Service Connection: sc-fabric-{environment}
connectionType: Generic
serverUrl: https://api.fabric.microsoft.com
authenticationType: OAuth2
```

### Deployment Pipeline Configuration

#### Azure DevOps YAML Pipeline Template

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    exclude:
    - docs/*
    - README.md

variables:
  - group: vg-fabricproject-shared

stages:
- stage: QualityAssurance
  displayName: 'Quality Assurance'
  jobs:
  - job: CodeQuality
    displayName: 'Code Quality Checks'
    steps:
    - template: templates/code-quality.yml
  
  - job: UnitTests
    displayName: 'Unit Tests'
    steps:
    - template: templates/unit-tests.yml
  
  - job: InfrastructureValidation
    displayName: 'Infrastructure Validation'
    steps:
    - template: templates/terraform-plan.yml

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: QualityAssurance
  condition: succeeded()
  variables:
  - group: vg-fabricproject-dev
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy to Development'
    environment: 'fabricproject-dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/deploy-infrastructure.yml
          - template: templates/deploy-fabric.yml
          - template: templates/smoke-tests.yml

- stage: DeployStaging
  displayName: 'Deploy to Staging'
  dependsOn: DeployDev
  condition: succeeded()
  variables:
  - group: vg-fabricproject-staging
  jobs:
  - deployment: DeployToStaging
    displayName: 'Deploy to Staging'
    environment: 'fabricproject-staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/deploy-infrastructure.yml
          - template: templates/deploy-fabric.yml
          - template: templates/integration-tests.yml

- stage: DeployProduction
  displayName: 'Deploy to Production'
  dependsOn: DeployStaging
  condition: succeeded()
  variables:
  - group: vg-fabricproject-prod
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy to Production'
    environment: 'fabricproject-prod'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/deploy-infrastructure.yml
          - template: templates/deploy-fabric.yml
          - template: templates/production-validation.yml
```

### Fabric Deployment Pipeline Integration

#### PowerShell Script for Fabric API Integration

```powershell
# scripts/Deploy-FabricWorkspace.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,
    
    [Parameter(Mandatory=$true)]
    [string]$AccessToken,
    
    [Parameter(Mandatory=$true)]
    [string]$SourceBranch,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetEnvironment
)

# Authenticate with Fabric API
$headers = @{
    'Authorization' = "Bearer $AccessToken"
    'Content-Type' = 'application/json'
}

# Update workspace from Git
$gitSyncBody = @{
    gitProviderDetails = @{
        branch = $SourceBranch
    }
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/git/commitToGit" -Method Post -Body $gitSyncBody -Headers $headers

# Deploy to target environment using deployment pipeline
$deployBody = @{
    sourceStageOrder = 0
    targetStageOrder = 1
    options = @{
        allowCreateArtifact = $true
        allowOverwriteArtifact = $true
    }
} | ConvertTo-Json

$deployResponse = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/pipelines/$DeploymentPipelineId/deploy" -Method Post -Body $deployBody -Headers $headers

Write-Output "Deployment initiated: $($deployResponse.operationId)"
```

### Testing Integration

#### Ephemeral Workspace Testing Strategy

```yaml
# templates/ephemeral-testing.yml
steps:
- task: AzurePowerShell@5
  displayName: 'Create Ephemeral Workspace'
  inputs:
    azureSubscription: '$(SERVICE_CONNECTION)'
    ScriptType: 'InlineScript'
    Inline: |
      # Create temporary workspace for testing
      $workspaceName = "ws-test-$(Build.BuildId)"
      $workspace = New-FabricWorkspace -Name $workspaceName -CapacityId $(FABRIC_CAPACITY_ID)
      Write-Host "##vso[task.setvariable variable=TEST_WORKSPACE_ID]$($workspace.Id)"

- task: AzurePowerShell@5
  displayName: 'Sync Test Branch to Workspace'
  inputs:
    azureSubscription: '$(SERVICE_CONNECTION)'
    ScriptType: 'InlineScript'
    Inline: |
      # Sync feature branch to test workspace
      $headers = @{ 'Authorization' = "Bearer $(FABRIC_ACCESS_TOKEN)" }
      $body = @{ gitProviderDetails = @{ branch = "$(Build.SourceBranch)" } } | ConvertTo-Json
      Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$(TEST_WORKSPACE_ID)/git/updateFromGit" -Method Post -Body $body -Headers $headers

- task: PythonScript@0
  displayName: 'Execute Integration Tests'
  inputs:
    scriptSource: 'filePath'
    scriptPath: 'tests/integration/run_tests.py'
    arguments: '--workspace-id $(TEST_WORKSPACE_ID)'

- task: AzurePowerShell@5
  displayName: 'Cleanup Ephemeral Workspace'
  condition: always()
  inputs:
    azureSubscription: '$(SERVICE_CONNECTION)'
    ScriptType: 'InlineScript'
    Inline: |
      # Clean up test workspace
      Remove-FabricWorkspace -WorkspaceId $(TEST_WORKSPACE_ID)
```

### Security and Compliance

#### Service Principal Configuration
```json
{
  "appRoles": [],
  "oauth2Permissions": [
    {
      "adminConsentDescription": "Access Fabric APIs",
      "adminConsentDisplayName": "Fabric API Access",
      "id": "guid",
      "type": "Admin",
      "value": "Fabric.ReadWrite.All"
    }
  ],
  "requiredResourceAccess": [
    {
      "resourceAppId": "00000009-0000-0000-c000-000000000000",
      "resourceAccess": [
        {
          "id": "tenant-specific-permission-id",
          "type": "Role"
        }
      ]
    }
  ]
}
```

#### Key Vault Integration
```yaml
# templates/secure-variables.yml
steps:
- task: AzureKeyVault@2
  displayName: 'Get secrets from Key Vault'
  inputs:
    azureSubscription: '$(SERVICE_CONNECTION)'
    KeyVaultName: '$(KEY_VAULT_NAME)'
    SecretsFilter: |
      fabric-service-principal-secret
      storage-account-key
      application-insights-key
    RunAsPreJob: true
```

## Monitoring and Alerting

### Pipeline Monitoring
- **Build success/failure rates**
- **Deployment duration tracking**
- **Test execution metrics**
- **Infrastructure drift detection**
- **Security scan results**

### Application Insights Integration
```yaml
# Custom telemetry in pipelines
- task: PowerShell@2
  displayName: 'Send Deployment Telemetry'
  inputs:
    targetType: 'inline'
    script: |
      $telemetry = @{
        name = "Deployment"
        properties = @{
          environment = "$(ENVIRONMENT_NAME)"
          buildId = "$(Build.BuildId)"
          deploymentStatus = "Success"
          duration = "$(DEPLOYMENT_DURATION)"
        }
      }
      Invoke-RestMethod -Uri "https://dc.applicationinsights.azure.com/v2/track" -Method Post -Body ($telemetry | ConvertTo-Json) -Headers @{'Content-Type'='application/json'}
```

## Troubleshooting Common Issues

### Authentication Failures
- Verify service principal permissions
- Check token expiration and renewal
- Validate service connection configuration
- Review Azure AD application registration

### Deployment Pipeline Issues
- Check variable group configurations
- Verify environment-specific parameters
- Review Terraform state lock conflicts
- Validate Fabric API permissions

### Git Synchronization Problems
- Ensure proper branch mapping configuration
- Check for merge conflicts in workspace
- Verify Git provider authentication
- Review workspace Git settings

### Performance Issues
- Monitor pipeline execution times
- Optimize parallel job execution
- Review resource allocation
- Implement caching strategies

## Best Practices Summary

1. **Use ephemeral resources** for testing to ensure clean validation
2. **Implement proper secret management** with Key Vault integration
3. **Maintain environment parity** with consistent configurations
4. **Use deployment slots** where available for zero-downtime deployments
5. **Implement proper monitoring** and alerting for pipeline health
6. **Document all pipeline configurations** and maintain runbooks
7. **Regularly review and update** security configurations
8. **Test disaster recovery procedures** and backup strategies

---

*This implementation guide provides enterprise-grade patterns for Fabric CI/CD pipelines. Customize the configurations based on your organization's specific requirements and security policies.*
