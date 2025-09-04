# Fabric Infrastructure as Code Template Generator

Use this prompt to generate comprehensive Terraform configurations for Microsoft Fabric infrastructure following enterprise best practices and proven deployment patterns.

---

**Prompt for GitHub Copilot:**

You are an expert in Microsoft Fabric infrastructure deployment and Terraform configuration. Generate comprehensive Infrastructure as Code (IaC) templates that follow enterprise best practices and proven patterns from production deployments.

Please help me create Terraform configurations for a complete Fabric environment that includes both Azure and Fabric resources with proper organization, security, and operational excellence.

## Infrastructure Requirements

### Azure Foundation Resources
Generate Terraform configurations for the core Azure infrastructure:

#### Storage and Data Services
- **Azure Data Lake Storage Gen2** with hierarchical namespace enabled
  - Container structure optimized for medallion architecture (bronze/silver/gold)
  - Lifecycle management policies for cost optimization
  - Blob versioning and soft delete for data protection
  - Network access rules and private endpoint support

- **Azure Key Vault** for secrets management
  - Soft delete and purge protection enabled
  - Appropriate access policies for service principals and users
  - Key rotation policies and audit logging
  - Network ACLs and private endpoint configuration

#### Monitoring and Observability
- **Application Insights** for telemetry and performance monitoring
  - Custom metrics and dashboards for Fabric workloads
  - Alert rules for critical failures and performance degradation
  - Integration with Azure Monitor for centralized logging

- **Log Analytics Workspace** for centralized log collection
  - Data retention policies aligned with compliance requirements
  - Custom log queries for troubleshooting and analysis
  - Integration with Fabric workspace monitoring

#### Compute and Capacity
- **Fabric Capacity** configuration (or reference to existing capacity)
  - Appropriate SKU sizing based on workload requirements
  - Auto-scaling configuration where supported
  - Cost monitoring and budget alerts

### Fabric Workspace Configuration
Generate Terraform configurations for Fabric-specific resources:

#### Core Workspace Setup
- **Fabric Workspace** with complete configuration
  - Git integration with repository connection
  - Proper naming conventions and tagging
  - Development settings and permissions
  - Deployment pipeline configuration

- **Fabric Lakehouse** with optimized structure
  - Shortcuts to Azure Data Lake Storage containers
  - Folder organization for medallion architecture
  - Security and access control configuration
  - OneLake integration settings

#### Development Environment
- **Fabric Environment** for custom libraries and dependencies
  - Python package management and versioning
  - Spark configuration optimization
  - Custom library installation and updates
  - Environment promotion across stages

- **Cloud Connections** to external resources
  - Secure authentication to storage accounts
  - Database connections with proper encryption
  - API connections with credential management
  - Network security and firewall rules

### DevOps Integration Resources
Configure resources for CI/CD and automation:

#### Service Identity and Security
- **Service Principal** for automated deployments
  - Minimal required permissions following least privilege principle
  - Certificate-based authentication where possible
  - Role assignments across Azure and Fabric resources
  - Key rotation and lifecycle management

- **Azure DevOps Integration** resources
  - Variable groups for environment-specific configuration
  - Service connections with managed identity authentication
  - Repository integration and webhook configuration
  - Pipeline permissions and security settings

## Configuration Management

### Environment Structure
Please create configurations for multiple environments:

**Development Environment**: `environments/dev.tfvars`
**Staging Environment**: `environments/staging.tfvars`
**Production Environment**: `environments/prod.tfvars`

### Terraform Organization
Structure the Terraform code with proper module organization:

```
infra/
├── terraform/
│   ├── modules/
│   │   ├── azure-foundation/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── fabric-workspace/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── devops-integration/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── staging/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
```

## Questions to Guide Configuration

Please ask me about my specific requirements:

### 1. Project and Naming Configuration
- **Project name and abbreviation**: What should I use for resource naming?
- **Environment strategy**: How many environments (dev/staging/prod) do you need?
- **Naming conventions**: Any specific organizational standards for resource names?
- **Tagging strategy**: What tags are required for governance and cost management?

### 2. Azure Infrastructure Details
- **Azure subscription and tenant**: Are you using existing or new subscriptions?
- **Regional deployment**: Which Azure regions should resources be deployed to?
- **Existing resources**: Do you have existing storage accounts, Key Vaults, or other resources to reference?
- **Network configuration**: Do you need VNet integration, private endpoints, or specific firewall rules?

### 3. Fabric Configuration Requirements
- **Capacity requirements**: Do you have existing Fabric capacity or need new capacity provisioning?
- **Workspace organization**: How many workspaces and what is the intended structure?
- **Git integration**: Which Git provider and repository structure are you using?
- **Data sources**: What external data sources need connection configuration?

### 4. Security and Compliance
- **Security requirements**: Any specific compliance standards (SOC2, HIPAA, PCI DSS)?
- **Access control**: How should permissions be structured across teams and environments?
- **Secret management**: What secrets and credentials need to be managed?
- **Audit requirements**: What level of audit logging and monitoring is needed?

### 5. Operational Requirements
- **Backup and recovery**: What are your RTO/RPO requirements?
- **Monitoring and alerting**: What metrics and alerts are critical for operations?
- **Cost management**: Any specific budgets or cost optimization requirements?
- **Scaling requirements**: Expected growth patterns and scaling needs?

## Generated Deliverables

Based on your requirements, I will provide:

### 1. Terraform Modules
- **Azure Foundation Module**: Core Azure resources with proper configuration
- **Fabric Workspace Module**: Complete Fabric workspace setup with dependencies
- **DevOps Integration Module**: CI/CD and automation resource configuration
- **Security Module**: Service principals, permissions, and access control

### 2. Environment Configurations
- **Variable Files**: Environment-specific parameter files
- **Backend Configuration**: Remote state management setup
- **Provider Configuration**: Azure and Fabric provider setup with proper versioning

### 3. Deployment Scripts
- **Bootstrap Script**: Initial setup and state backend creation
- **Deployment Script**: Environment deployment and validation
- **Cleanup Script**: Resource cleanup and cost optimization

### 4. Documentation
- **Deployment Guide**: Step-by-step deployment instructions
- **Configuration Reference**: Parameter descriptions and examples
- **Troubleshooting Guide**: Common issues and resolution steps
- **Security Guide**: Access control and security configuration details

## Implementation Best Practices

The generated configurations will include:

### Resource Naming and Organization
- **Consistent naming conventions** following Azure and Fabric best practices
- **Proper resource tagging** for governance, cost management, and lifecycle tracking
- **Logical resource grouping** with appropriate dependencies and references

### Security Configuration
- **Least privilege access** with role-based security implementation
- **Secret management** using Azure Key Vault integration
- **Network security** with appropriate firewall rules and private endpoints
- **Audit logging** and compliance monitoring configuration

### Operational Excellence
- **Remote state management** with proper locking and backup
- **Environment isolation** with separate state files and configurations
- **Disaster recovery** configuration and backup strategies
- **Cost optimization** with lifecycle policies and monitoring

### Performance and Scalability
- **Resource sizing** based on expected workloads and growth patterns
- **Auto-scaling configuration** where supported by the services
- **Performance monitoring** with custom metrics and dashboards
- **Capacity planning** guidance and recommendations

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Answer the configuration questions with your specific requirements
3. Review and customize the generated Terraform configurations
4. Test in development environment before deploying to staging/production
5. Follow the deployment guide for step-by-step implementation

**Note**: The generated configurations follow enterprise patterns and can be integrated with the CI/CD pipelines and testing frameworks from other Copilot artifacts in this collection.
