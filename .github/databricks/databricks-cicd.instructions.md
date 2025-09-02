# Azure Databricks CI/CD Implementation Instructions

This document provides detailed guidance for implementing robust CI/CD pipelines for Azure Databricks projects with Unity Catalog, following proven enterprise patterns from the parking sensors sample implementation.

## CI/CD Pipeline Architecture Overview

The CI/CD implementation follows a multi-stage approach with clear separation of concerns:

1. **Quality Assurance (QA) Pipelines** - Triggered on pull requests
2. **Build Artifacts Pipeline** - Triggered on main branch commits  
3. **Release Pipeline** - Multi-stage deployment with approval gates
4. **Integration Testing** - Automated validation in staging environment

## Quality Assurance (QA) Pipelines

### Python QA Pipeline (`azure-pipelines-ci-qa-python.yml`)

**Purpose**: Validate Python code quality, run unit tests, and ensure package builds successfully

**Trigger Configuration**:
```yaml
trigger: none  # Only runs on PR, not on main branch

pr:
  branches:
    include:
    - main
  paths:
    include:
    - src/*
    - tests/*
    - requirements.txt
    - setup.py
```

**Key Stages**:

1. **Code Quality Checks**:
   ```yaml
   - task: UsePythonVersion@0
     inputs:
       versionSpec: '3.8'
   
   - script: |
       python -m pip install --upgrade pip
       pip install flake8 pytest pytest-cov
       pip install -r requirements.txt
     displayName: 'Install dependencies'
   
   - script: |
       flake8 src/ --count --select=E9,F63,F7,F82 --show-source --statistics
       flake8 src/ --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
     displayName: 'Lint with flake8'
   ```

2. **Unit Test Execution**:
   ```yaml
   - script: |
       pytest src/*/tests/ --junitxml=junit/test-results.xml --cov=src --cov-report=xml
     displayName: 'Run unit tests'
   
   - task: PublishTestResults@2
     condition: succeededOrFailed()
     inputs:
       testResultsFiles: '**/test-*.xml'
       testRunTitle: 'Publish test results for Python'
   
   - task: PublishCodeCoverageResults@1
     inputs:
       codeCoverageTool: Cobertura
       summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'
   ```

3. **Package Build Validation**:
   ```yaml
   - script: |
       python setup.py bdist_wheel
     displayName: 'Build Python package'
   
   - task: PublishPipelineArtifact@1
     inputs:
       artifactName: 'python-wheel-qa'
       path: 'dist/'
   ```

### Infrastructure QA Pipeline (Optional)

**Purpose**: Validate Bicep templates and infrastructure configurations

```yaml
- task: AzureCLI@2
  displayName: 'Validate Bicep Templates'
  inputs:
    azureSubscription: '$(azureServiceConnection)'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az bicep build --file infrastructure/main.bicep
      az deployment group validate \
        --resource-group $(rgName) \
        --template-file infrastructure/main.bicep \
        --parameters @infrastructure/main.parameters.dev.json
```

## Build Artifacts Pipeline

### Main Build Pipeline (`azure-pipelines-ci-artifacts.yml`)

**Purpose**: Build production-ready artifacts and prepare for deployment

**Trigger Configuration**:
```yaml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - src/*
    - databricks/*
    - infrastructure/*
```

**Key Stages**:

1. **Python Package Build**:
   ```yaml
   - stage: BuildPythonPackage
     displayName: 'Build Python Package'
     jobs:
     - job: BuildWheel
       displayName: 'Build Python Wheel'
       steps:
       - task: UsePythonVersion@0
         inputs:
           versionSpec: '3.8'
       
       - script: |
           python -m pip install --upgrade pip setuptools wheel
           pip install -r requirements.txt
         displayName: 'Install dependencies'
       
       - script: |
           python setup.py bdist_wheel
         displayName: 'Build wheel package'
       
       - task: PublishPipelineArtifact@1
         inputs:
           artifactName: 'python-wheel'
           path: 'dist/'
   ```

2. **Infrastructure Artifacts**:
   ```yaml
   - stage: PublishInfrastructure
     displayName: 'Publish Infrastructure'
     jobs:
     - job: PublishBicep
       displayName: 'Publish Bicep Templates'
       steps:
       - task: PublishPipelineArtifact@1
         inputs:
           artifactName: 'infrastructure'
           path: 'infrastructure/'
   ```

3. **Databricks Artifacts**:
   ```yaml
   - stage: PublishDatabricks
     displayName: 'Publish Databricks Artifacts'
     jobs:
     - job: PublishNotebooks
       displayName: 'Publish Notebooks and Configs'
       steps:
       - task: PublishPipelineArtifact@1
         inputs:
           artifactName: 'databricks-notebooks'
           path: 'databricks/notebooks/'
       
       - task: PublishPipelineArtifact@1
         inputs:
           artifactName: 'databricks-config'
           path: 'databricks/config/'
   ```

## Release Pipeline Implementation

### Multi-Stage Release Pipeline (`azure-pipelines-cd-release.yml`)

**Purpose**: Deploy artifacts across environments with proper governance

**Trigger Configuration**:
```yaml
trigger: none  # Triggered by completion of build pipeline

resources:
  pipelines:
  - pipeline: BuildPipeline
    source: '{project-name}-ci-artifacts'
    trigger:
      branches:
        include:
        - main
```

### Stage 1: Development Environment

```yaml
- stage: DeployToDev
  displayName: 'Deploy to Development'
  variables:
  - group: '{project-name}-release-dev'
  - group: '{project-name}-secrets-dev'
  
  jobs:
  - deployment: DeployInfrastructure
    displayName: 'Deploy Infrastructure'
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'infrastructure'
              path: '$(System.DefaultWorkingDirectory)/infrastructure'
          
          - task: AzureCLI@2
            displayName: 'Deploy Bicep Infrastructure'
            inputs:
              azureSubscription: '$(azureServiceConnection)'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az deployment group create \
                  --resource-group $(rgName) \
                  --template-file infrastructure/main.bicep \
                  --parameters @infrastructure/main.parameters.dev.json \
                  --parameters deployment_id=$(deploymentId)

  - deployment: DeployDatabricks
    displayName: 'Deploy Databricks Artifacts'
    dependsOn: DeployInfrastructure
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'python-wheel'
              path: '$(System.DefaultWorkingDirectory)/dist'
          
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'databricks-notebooks'
              path: '$(System.DefaultWorkingDirectory)/notebooks'
          
          - task: UsePythonVersion@0
            inputs:
              versionSpec: '3.8'
          
          - script: |
              pip install databricks-cli
            displayName: 'Install Databricks CLI'
          
          - task: PythonScript@0
            displayName: 'Upload Python Package to DBFS'
            inputs:
              scriptSource: 'inline'
              script: |
                import os
                import subprocess
                
                # Configure Databricks CLI
                os.environ['DATABRICKS_HOST'] = '$(databricksWorkspaceUrl)'
                os.environ['DATABRICKS_TOKEN'] = '$(databricksToken)'
                
                # Upload wheel file to DBFS
                wheel_files = [f for f in os.listdir('dist') if f.endswith('.whl')]
                for wheel_file in wheel_files:
                    subprocess.run([
                        'databricks', 'fs', 'cp', 
                        f'dist/{wheel_file}', 
                        f'$(databricksDbfsLibPath)/{wheel_file}',
                        '--overwrite'
                    ])
          
          - task: PythonScript@0
            displayName: 'Upload Notebooks to Workspace'
            inputs:
              scriptSource: 'inline'
              script: |
                import os
                import subprocess
                
                # Configure Databricks CLI
                os.environ['DATABRICKS_HOST'] = '$(databricksWorkspaceUrl)'
                os.environ['DATABRICKS_TOKEN'] = '$(databricksToken)'
                
                # Upload notebooks
                subprocess.run([
                    'databricks', 'workspace', 'import_dir',
                    'notebooks',
                    '$(databricksNotebookPath)',
                    '--overwrite'
                ])
```

### Stage 2: Staging Environment (with Approval Gate)

```yaml
- stage: DeployToStaging
  displayName: 'Deploy to Staging'
  dependsOn: DeployToDev
  condition: succeeded()
  variables:
  - group: '{project-name}-release-stg'
  - group: '{project-name}-secrets-stg'
  
  jobs:
  - deployment: ApprovalGate
    displayName: 'Approval Gate for Staging'
    environment: 'staging'  # Configure manual approval in Azure DevOps
    
  # Similar deployment jobs as Dev but with staging variables
```

### Stage 3: Integration Testing

```yaml
- stage: IntegrationTesting
  displayName: 'Run Integration Tests'
  dependsOn: DeployToStaging
  variables:
  - group: '{project-name}-release-stg'
  - group: '{project-name}-secrets-stg'
  
  jobs:
  - job: RunIntegrationTests
    displayName: 'Execute Integration Test Suite'
    steps:
    - task: DownloadPipelineArtifact@2
      inputs:
        artifactName: 'infrastructure'
        path: '$(System.DefaultWorkingDirectory)'
    
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.8'
    
    - script: |
        pip install pytest databricks-cli great-expectations
        pip install -r requirements.txt
      displayName: 'Install test dependencies'
    
    - task: PythonScript@0
      displayName: 'Run Integration Tests'
      inputs:
        scriptSource: 'inline'
        script: |
          import os
          import subprocess
          import pytest
          
          # Configure environment for tests
          os.environ['DATABRICKS_HOST'] = '$(databricksWorkspaceUrl)'
          os.environ['DATABRICKS_TOKEN'] = '$(databricksToken)'
          os.environ['AZURE_STORAGE_ACCOUNT'] = '$(datalakeAccountName)'
          os.environ['AZURE_STORAGE_KEY'] = '$(datalakeKey)'
          
          # Run integration tests
          exit_code = pytest.main([
              'tests/integrationtests/',
              '--junitxml=integration-test-results.xml',
              '-v'
          ])
          
          exit(exit_code)
    
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs:
        testResultsFiles: '**/integration-test-results.xml'
        testRunTitle: 'Integration Test Results'
```

### Stage 4: Production Deployment (with Approval Gate)

```yaml
- stage: DeployToProduction
  displayName: 'Deploy to Production'
  dependsOn: IntegrationTesting
  condition: succeeded()
  variables:
  - group: '{project-name}-release-prod'
  - group: '{project-name}-secrets-prod'
  
  jobs:
  - deployment: ProductionApprovalGate
    displayName: 'Production Approval Gate'
    environment: 'production'  # Configure manual approval in Azure DevOps
    
  # Production deployment jobs with additional safety checks
```

## Variable Groups Configuration

### Required Variable Groups

**Release Variables** (`{project-name}-release-{env}`):
```
- azureLocation: "East US 2"
- rgName: "rg-{project}-{env}"
- databricksWorkspaceUrl: "https://adb-123456789.azuredatabricks.net"
- databricksNotebookPath: "/Shared/notebooks"
- databricksDbfsLibPath: "dbfs:/mnt/datalake/sys/databricks/libs"
- datalakeAccountName: "st{project}{env}001"
- unityCatalogName: "{project}_catalog_{env}"
- clusterPolicyId: "policy-id-for-{env}"
```

**Secret Variables** (`{project-name}-secrets-{env}`) - Linked to Key Vault:
```
- databricksToken: "dapi123..."
- datalakeKey: "storage-account-key"
- servicePrincipalId: "sp-client-id"
- servicePrincipalSecret: "sp-client-secret"
- tenantId: "tenant-id"
```

## Service Connections Required

1. **Azure Service Connections** (one per environment):
   - `azure-service-connection-dev`
   - `azure-service-connection-stg` 
   - `azure-service-connection-prod`

2. **GitHub Service Connection** (if using GitHub):
   - `github-service-connection`

## Unity Catalog Deployment Automation

### Catalog and Schema Creation

```python
# Deploy Unity Catalog structure via Python script
import requests
import json

def create_unity_catalog_structure(workspace_url, token, catalog_name):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    # Create catalog
    catalog_payload = {
        "name": catalog_name,
        "comment": f"Data catalog for {catalog_name.split('_')[-1]} environment"
    }
    
    response = requests.post(
        f'{workspace_url}/api/2.1/unity-catalog/catalogs',
        headers=headers,
        data=json.dumps(catalog_payload)
    )
    
    if response.status_code == 201:
        print(f"Catalog {catalog_name} created successfully")
    
    # Create schemas
    schemas = ['bronze', 'silver', 'gold', 'utilities']
    for schema in schemas:
        schema_payload = {
            "name": schema,
            "catalog_name": catalog_name,
            "comment": f"{schema.capitalize()} layer for medallion architecture"
        }
        
        response = requests.post(
            f'{workspace_url}/api/2.1/unity-catalog/schemas',
            headers=headers,
            data=json.dumps(schema_payload)
        )
        
        if response.status_code == 201:
            print(f"Schema {catalog_name}.{schema} created successfully")
```

## Monitoring and Alerting

### Pipeline Monitoring

1. **Azure DevOps Analytics**:
   - Track deployment success rates
   - Monitor pipeline duration trends
   - Alert on consecutive failures

2. **Custom Metrics**:
   ```yaml
   - task: AzureCLI@2
     displayName: 'Send Deployment Metrics'
     inputs:
       azureSubscription: '$(azureServiceConnection)'
       scriptType: 'bash'
       scriptLocation: 'inlineScript'
       inlineScript: |
         az monitor metrics send \
           --resource-group $(rgName) \
           --name "deployment.success" \
           --value 1 \
           --timestamp $(date -u +%Y-%m-%dT%H:%M:%SZ)
   ```

### Application Insights Integration

```python
# Custom telemetry in deployment scripts
from applicationinsights import TelemetryClient
import os

tc = TelemetryClient(os.environ['APPLICATION_INSIGHTS_KEY'])

def track_deployment_event(stage, success, duration):
    tc.track_event(
        'deployment_stage_completed',
        {
            'stage': stage,
            'success': str(success),
            'environment': os.environ['ENVIRONMENT']
        },
        {
            'duration_seconds': duration
        }
    )
    tc.flush()
```

## Best Practices and Recommendations

### Pipeline Security
- **Use managed identities** where possible instead of service principal secrets
- **Limit service principal permissions** to minimum required scope
- **Rotate secrets regularly** and monitor for unauthorized usage
- **Enable pipeline audit logging** for compliance tracking

### Performance Optimization
- **Use pipeline artifacts efficiently** to avoid unnecessary downloads
- **Implement parallel deployments** where safe (non-conflicting resources)
- **Cache dependencies** in build agents to reduce setup time
- **Use self-hosted agents** for consistent performance

### Error Handling and Recovery
- **Implement retry logic** for transient failures
- **Use deployment conditionals** to skip stages on specific failures
- **Maintain rollback capabilities** for critical production deployments
- **Document troubleshooting procedures** for common pipeline issues

### Testing Strategy
- **Run unit tests on every PR** to catch issues early
- **Execute integration tests** in staging before production
- **Implement smoke tests** in production post-deployment
- **Use feature flags** for gradual rollout of changes

---

*This CI/CD implementation follows proven enterprise patterns and should be customized based on your organization's specific requirements, compliance needs, and operational procedures.*
