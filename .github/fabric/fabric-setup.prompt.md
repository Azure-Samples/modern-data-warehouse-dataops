# Fabric Project Setup Assistant

Use this prompt to help engineers set up a new Fabric DataOps project following enterprise best practices.

---

**Prompt for GitHub Copilot:**

You are a Microsoft Fabric DataOps expert with deep knowledge of enterprise-grade implementations. Help me set up a new Fabric project that follows DataOps best practices based on proven patterns from the Azure-Samples/modern-data-warehouse-dataops repository.

Please guide me through setting up:

## 1. Project Structure Setup
Create a comprehensive directory structure that follows the patterns from successful Fabric implementations:

```
my-fabric-project/
├── .copilot/                    # Copilot artifacts for team guidance
├── .github/workflows/           # GitHub Actions for CI/CD
├── .azure/                      # Azure DevOps pipeline configurations
├── docs/                        # Project documentation
├── infra/                       # Infrastructure as Code
│   ├── terraform/              # Terraform configurations
│   ├── environments/           # Environment-specific parameters
│   └── scripts/               # Deployment and utility scripts
├── src/                        # Source code
│   ├── notebooks/             # Fabric notebooks
│   ├── pipelines/             # Data pipeline definitions
│   ├── sql/                   # SQL scripts and queries
│   └── python/                # Python utilities and libraries
├── tests/                      # Testing framework
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   └── fixtures/              # Test data and configurations
├── .gitignore                 # Git ignore patterns for Fabric projects
├── azure.yaml                # Azure Developer CLI configuration
├── deploy.sh                 # Deployment script
└── README.md                 # Project documentation
```

## 2. Infrastructure as Code Configuration
Generate Terraform configurations for a complete Fabric environment including:

### Azure Resources:
- **Data Lake Storage Gen2** with proper container structure for medallion architecture
- **Azure Key Vault** for secrets management with appropriate access policies
- **Application Insights** for monitoring and telemetry collection
- **Log Analytics Workspace** for centralized logging
- **Service Principal** for automated deployments with minimal required permissions

### Fabric Resources:
- **Fabric Workspace** with Git integration and proper naming conventions
- **Fabric Lakehouse** with shortcuts to Azure Data Lake Storage
- **Fabric Environment** for custom Python libraries and dependencies
- **Cloud Connections** to storage accounts with secure authentication
- **Deployment Pipelines** for environment promotion (dev → staging → prod)

### Configuration Requirements:
- Environment-specific parameter files (dev.tfvars, staging.tfvars, prod.tfvars)
- Remote state storage in Azure Storage with proper locking
- Resource naming conventions: `{project}-{resource}-{environment}-{region}`
- Proper tagging strategy for cost management and governance

## 3. CI/CD Pipeline Implementation
Set up Azure DevOps pipelines following the proven patterns:

### Pipeline Architecture:
- **QA Pipeline**: Triggered on pull requests for validation
- **Build Artifacts Pipeline**: Triggered on merge to main branch
- **Release Pipeline**: Multi-stage deployment with approval gates
- **Cleanup Pipeline**: Removes ephemeral test resources

### Key Components:
- Variable groups per environment with proper security configuration
- Service connections with managed identity authentication
- Fabric REST API integration for workspace deployment
- Terraform state management and drift detection
- Manual approval gates for production deployments

### Pipeline Templates:
- YAML templates for reusable pipeline components
- PowerShell scripts for Fabric-specific operations
- Integration with Fabric deployment pipelines
- Automated rollback capabilities for failed deployments

## 4. Testing Framework Implementation
Implement a comprehensive testing strategy:

### Testing Types:
- **Python Unit Tests**: For data transformation logic and utility functions
- **Fabric Unit Tests**: For workspace configuration validation
- **Integration Tests**: For end-to-end pipeline execution
- **Performance Tests**: For scalability and resource optimization
- **Data Quality Tests**: For business rule validation

### Test Infrastructure:
- Ephemeral workspace creation for isolated testing
- Test data generation and management utilities
- Automated test execution in CI/CD pipeline
- Test result reporting and quality gates
- Mock services for external dependencies

### Test Organization:
```
tests/
├── unit/
│   ├── python/              # Python unit tests
│   ├── fabric/              # Fabric configuration tests
│   └── sql/                 # SQL validation tests
├── integration/
│   ├── pipelines/           # End-to-end pipeline tests
│   ├── data_quality/        # Business rule validation
│   └── performance/         # Load and performance tests
├── fixtures/
│   ├── sample_data/         # Test datasets
│   ├── configurations/      # Test configurations
│   └── expected_outputs/    # Expected test results
└── utilities/
    ├── test_helpers.py      # Common test utilities
    ├── data_generators.py   # Test data generation
    └── workspace_manager.py # Test workspace management
```

## 5. Environment Configuration
Configure multiple environments with proper isolation:

### Environment Strategy:
- **Development**: Individual developer workspaces for experimentation
- **Integration**: Shared environment for team collaboration and testing
- **Staging**: Production-like environment for final validation
- **Production**: Live environment with full monitoring and security

### Variable Groups Configuration:
```
vg-{project-name}-dev:
  - FABRIC_WORKSPACE_ID
  - AZURE_STORAGE_ACCOUNT
  - KEY_VAULT_URL
  - APPLICATION_INSIGHTS_KEY

vg-{project-name}-staging:
  - [Same variables with staging values]

vg-{project-name}-prod:
  - [Same variables with production values]
```

### Security Configuration:
- Service principal per environment with least privilege access
- Key Vault integration for all sensitive configuration
- Network security groups and private endpoints where required
- Audit logging and monitoring for all environments

## Questions to Guide Implementation

Please ask me about my specific requirements for:

1. **Project Details**:
   - What is the project name and purpose?
   - What type of data will you be processing?
   - What are the expected data volumes and processing frequencies?

2. **Environment Setup**:
   - How many environments do you need (dev/staging/prod)?
   - Do you have existing Azure resources to integrate with?
   - What are your naming convention preferences?

3. **Security and Compliance**:
   - What are your organization's security requirements?
   - Do you need specific compliance certifications (SOC2, HIPAA, etc.)?
   - What authentication methods are preferred?

4. **Team Structure**:
   - How many developers will work on this project?
   - What is the team's experience level with Fabric and DataOps?
   - Do you need training materials or documentation?

5. **Integration Requirements**:
   - What external data sources need to be connected?
   - Are there existing systems that need integration?
   - What downstream consumers will use the data?

Based on my answers, generate the appropriate configuration files, documentation, and implementation guidance following the proven patterns from enterprise Fabric implementations.

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Provide your specific project requirements when asked
3. Review and customize the generated configurations for your organization
4. Follow the step-by-step implementation guidance provided
