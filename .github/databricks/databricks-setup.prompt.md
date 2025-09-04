# Databricks Project Setup Assistant

Use this prompt to help engineers set up a new Azure Databricks DataOps project following enterprise best practices including Unity Catalog, medallion architecture, and comprehensive CI/CD pipelines.

---

**Prompt for GitHub Copilot:**

You are an Azure Databricks DataOps expert with deep knowledge of enterprise-grade implementations including Unity Catalog, medallion architecture, and modern CI/CD practices. Help me set up a new Databricks project that follows DataOps best practices based on proven patterns from the Azure-Samples/modern-data-warehouse-dataops repository.

Please guide me through setting up:

## 1. Project Structure Setup
Create a comprehensive directory structure that follows the patterns from successful Databricks implementations:

```
my-databricks-project/
├── .copilot/                    # Copilot artifacts for team guidance
├── .github/workflows/           # GitHub Actions for CI/CD (optional)
├── .azure/                      # Azure DevOps pipeline configurations
├── .devcontainer/              # Dev container configuration for consistency
├── docs/                        # Project documentation
│   ├── architecture.md        # Solution architecture documentation
│   ├── deployment.md          # Deployment instructions
│   └── troubleshooting.md     # Common issues and solutions
├── infrastructure/             # Infrastructure as Code
│   ├── main.bicep             # Main Bicep template
│   ├── main.parameters.*.json # Environment-specific parameters
│   └── modules/               # Bicep modules for resources
│       ├── databricks.bicep   # Databricks workspace configuration
│       ├── storage.bicep      # ADLS Gen2 storage setup
│       ├── keyvault.bicep     # Key Vault for secrets
│       ├── unity_catalog.bicep # Unity Catalog setup
│       └── monitoring.bicep   # Application Insights & Log Analytics
├── devops/                     # CI/CD pipeline definitions
│   ├── azure-pipelines-ci-qa-python.yml    # Python QA pipeline
│   ├── azure-pipelines-ci-artifacts.yml     # Build artifacts pipeline
│   ├── azure-pipelines-cd-release.yml       # Release pipeline
│   └── templates/             # Reusable pipeline templates
│       ├── jobs/              # Job templates
│       └── steps/             # Step templates
├── databricks/                 # Databricks-specific configurations
│   ├── notebooks/             # Databricks notebooks
│   │   ├── bronze/            # Raw data ingestion notebooks
│   │   ├── silver/            # Data cleansing and validation
│   │   ├── gold/              # Business logic and dimensional models
│   │   └── utilities/         # Shared utility notebooks
│   └── config/                # Databricks configurations
│       ├── cluster_policies.json    # Cluster policy definitions
│       └── workspace_config.json   # Workspace configuration
├── src/                        # Source code packages
│   └── {project_name}_transform/ # Python package for data transformations
│       ├── __init__.py
│       ├── bronze.py          # Bronze layer processing
│       ├── silver.py          # Silver layer processing
│       ├── gold.py            # Gold layer processing
│       ├── utilities.py       # Common utilities
│       ├── config.py          # Configuration management
│       └── tests/             # Unit tests for the package
│           ├── __init__.py
│           ├── test_bronze.py
│           ├── test_silver.py
│           ├── test_gold.py
│           └── fixtures/      # Test data and configurations
├── tests/                      # Integration and system tests
│   ├── integrationtests/      # End-to-end pipeline tests
│   │   ├── __init__.py
│   │   ├── test_pipeline_execution.py
│   │   └── test_data_quality.py
│   └── fixtures/              # Test data and configurations
│       ├── sample_data/       # Sample datasets for testing
│       └── expected_outputs/  # Expected test results
├── data/                       # Sample and test data
│   ├── bronze/                # Raw data samples
│   ├── silver/                # Processed data samples
│   └── gold/                  # Final output samples
├── scripts/                    # Utility and deployment scripts
│   ├── deploy.sh              # Main deployment script
│   ├── setup_environment.sh   # Environment setup
│   └── cleanup.sh             # Resource cleanup
├── .gitignore                 # Git ignore patterns for Databricks projects
├── .envtemplate               # Environment variables template
├── requirements.txt           # Python dependencies
├── setup.py                   # Python package setup
├── azure.yaml                # Azure Developer CLI configuration
├── pyproject.toml            # Python project configuration
└── README.md                 # Project documentation
```

## 2. Infrastructure as Code Configuration
Generate Bicep configurations for a complete Databricks environment including:

### Azure Resources:
- **Azure Databricks Workspace** with Unity Catalog enabled and proper networking
- **ADLS Gen2 Storage Accounts** (data lake + Unity Catalog metastore)
- **Unity Catalog Metastore** with external locations and storage credentials
- **Azure Key Vault** for secrets management with Databricks secret scope integration
- **Application Insights** for monitoring and telemetry collection
- **Log Analytics Workspace** for centralized logging and cluster monitoring
- **Azure Data Factory** for orchestration (if required)
- **Service Principals** for automation with minimal required permissions

### Unity Catalog Configuration:
- **Metastore** with proper region configuration and admin assignments
- **Catalogs** per environment (dev, staging, prod) with appropriate naming
- **External Locations** pointing to ADLS Gen2 containers with proper access
- **Storage Credentials** using managed identities for secure authentication
- **Schemas** organized by data layer (bronze, silver, gold)

### Environment-Specific Parameters:
```bicep
// main.parameters.dev.json
{
  "project": "myproject",
  "env": "dev",
  "location": "East US 2",
  "deployment_id": "001",
  "enable_monitoring": true,
  "databricks_sku": "standard",
  "unity_catalog_enabled": true
}
```

### Resource Naming Conventions:
- Databricks Workspace: `dbw-{project}-{env}-{deployment_id}`
- Storage Account: `st{project}{env}{deployment_id}`
- Key Vault: `kv-{project}-{env}-{deployment_id}`
- Unity Catalog: `{project}_catalog_{env}`

## 3. CI/CD Pipeline Implementation
Set up Azure DevOps pipelines following the proven multi-stage approach:

### Pipeline Architecture:
- **Python QA Pipeline**: Runs unit tests and linting on pull requests
- **Build Artifacts Pipeline**: Builds Python packages and publishes artifacts
- **Release Pipeline**: Multi-stage deployment with approval gates
- **Integration Test Pipeline**: Validates end-to-end functionality

### Key Pipeline Components:
```yaml
# azure-pipelines-ci-artifacts.yml structure
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - src/*
    - databricks/*
    - infrastructure/*

stages:
- stage: Build
  jobs:
  - job: BuildPythonPackage
    steps:
    - task: UsePythonVersion@0
    - task: PythonScript@0  # Run unit tests
    - task: PythonScript@0  # Build wheel package
    - task: PublishPipelineArtifact@1  # Publish artifacts

- stage: PublishToDatabricks
  jobs:
  - job: DeployNotebooks
    steps:
    - task: UsePythonVersion@0
    - task: PythonScript@0  # Deploy notebooks via Databricks CLI
```

### Variable Groups Configuration:
```
Variable Group: {project}-release-dev
- databricksWorkspaceUrl
- databricksToken (linked to Key Vault)
- storageAccountName
- unityCatalogName
- clusterPolicyId

Variable Group: {project}-secrets-dev (linked to Key Vault)
- databricksToken
- storageAccountKey
- servicePrincipalSecret
```

## 4. Unity Catalog Setup
Configure comprehensive data governance:

### Catalog Structure:
```sql
-- Environment-specific catalogs
CREATE CATALOG {project}_catalog_dev;
CREATE CATALOG {project}_catalog_staging;
CREATE CATALOG {project}_catalog_prod;

-- Schema organization by medallion layer
CREATE SCHEMA {project}_catalog_dev.bronze;
CREATE SCHEMA {project}_catalog_dev.silver;
CREATE SCHEMA {project}_catalog_dev.gold;
CREATE SCHEMA {project}_catalog_dev.utilities;
```

### External Locations:
```sql
-- Create storage credential using managed identity
CREATE STORAGE CREDENTIAL {project}_storage_credential_{env}
USING AZURE_MANAGED_IDENTITY '/subscriptions/{subscription}/resourceGroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity}';

-- Create external location for data lake
CREATE EXTERNAL LOCATION {project}_data_location_{env}
URL 'abfss://data@{storage_account}.dfs.core.windows.net/'
WITH (STORAGE_CREDENTIAL {project}_storage_credential_{env});
```

### Permissions Strategy:
- **Data Engineers**: CREATE privileges on dev catalog, READ on staging/prod
- **Data Scientists**: READ privileges on all catalogs
- **Service Principals**: Specific privileges for automated pipelines
- **Analysts**: READ privileges on gold layer only

## 5. Testing Framework Implementation
Implement comprehensive testing across all layers:

### Python Unit Tests:
```python
# src/{project}_transform/tests/test_bronze.py
import pytest
from pyspark.sql import SparkSession
from {project}_transform.bronze import process_raw_data

@pytest.fixture
def spark():
    return SparkSession.builder.master("local[2]").getOrCreate()

def test_bronze_processing(spark):
    # Arrange
    input_df = spark.read.json("tests/fixtures/sample_raw_data.json")
    
    # Act
    result_df = process_raw_data(input_df)
    
    # Assert
    assert result_df.count() > 0
    assert "processed_timestamp" in result_df.columns
```

### Integration Tests:
```python
# tests/integrationtests/test_pipeline_execution.py
import pytest
from databricks_cli.sdk.api_client import ApiClient
from databricks_cli.jobs.api import JobsApi

class TestPipelineExecution:
    def test_end_to_end_pipeline(self):
        # Test complete pipeline execution
        # Validate data quality
        # Check Unity Catalog table creation
        pass
```

### Data Quality Testing:
```python
# Great Expectations integration
from great_expectations.dataset import SparkDFDataset

def validate_silver_data_quality(df):
    ge_df = SparkDFDataset(df)
    
    # Validate data completeness
    result = ge_df.expect_column_to_not_be_null("id")
    assert result.success
    
    # Validate data ranges
    result = ge_df.expect_column_values_to_be_between("amount", 0, 1000000)
    assert result.success
```

## 6. Environment Configuration
Configure multiple environments with Unity Catalog isolation:

### Environment Strategy:
- **Development**: Individual developer catalogs for experimentation
- **Integration**: Shared environment for team collaboration and testing  
- **Staging**: Production-like environment for final validation
- **Production**: Live environment with full monitoring and governance

### Cluster Policies:
```json
{
  "cluster_type": {
    "type": "allowlist",
    "values": ["all-purpose-compute", "job-compute"]
  },
  "autotermination_minutes": {
    "type": "range",
    "maxValue": 120
  },
  "instance_pool_id": {
    "type": "allowlist", 
    "values": ["pool-id-for-dev", "pool-id-for-prod"]
  }
}
```

### Security Configuration:
- Service principal per environment with Unity Catalog permissions
- Managed identity for storage access without keys
- Key Vault integration for all sensitive configuration
- Network security groups and private endpoints for production
- Comprehensive audit logging for all environments

## Questions to Guide Implementation

Please ask me about my specific requirements for:

1. **Project Details**:
   - What is the project name and primary use case?
   - What type of data sources will you be processing?
   - What are the expected data volumes and processing frequencies?
   - Do you need real-time or batch processing capabilities?

2. **Environment and Infrastructure**:
   - How many environments do you need (dev/staging/prod)?
   - Do you have existing Azure resources or Unity Catalog setup?
   - What are your regional requirements for data residency?
   - Do you need multi-region deployment capabilities?

3. **Security and Compliance**:
   - What are your organization's security and governance requirements?
   - Do you need specific compliance certifications (SOC2, HIPAA, etc.)?
   - What authentication methods are preferred (Azure AD, service principals)?
   - Are there data classification or sensitivity requirements?

4. **Team and Development**:
   - How many developers will work on this project?
   - What is the team's experience level with Databricks and Unity Catalog?
   - Do you prefer Azure DevOps or GitHub Actions for CI/CD?
   - Do you need training materials and documentation?

5. **Data Architecture**:
   - What medallion architecture layers do you need (bronze/silver/gold)?
   - Are there specific data transformation requirements?
   - Do you need streaming or batch processing patterns?
   - What downstream systems will consume the data?

6. **Integration Requirements**:
   - What external data sources need to be connected?
   - Do you need Azure Data Factory for orchestration?
   - Are there existing systems that require integration?
   - What BI tools will connect to the final data?

Based on my answers, generate the appropriate Bicep templates, pipeline configurations, Python package structure, Unity Catalog setup scripts, and comprehensive documentation following the proven patterns from enterprise Databricks implementations.

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Provide your specific project requirements when asked
3. Review and customize the generated configurations for your organization
4. Follow the step-by-step implementation guidance provided
5. Use the generated deploy.sh script to provision your environment
