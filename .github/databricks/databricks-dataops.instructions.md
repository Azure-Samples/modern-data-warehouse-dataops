# Azure Databricks DataOps Engineering Instructions

This document provides guidance for implementing DataOps best practices in Azure Databricks projects, based on proven patterns from enterprise implementations including Unity Catalog, medallion architecture, and comprehensive CI/CD pipelines.

## Core DataOps Principles for Databricks

### Infrastructure as Code (IaC)
- **Use Bicep or Terraform** for consistent Azure Databricks workspace deployments
- **Separate concerns**: Azure infrastructure from Databricks workspace configuration
- **Store state remotely** for team collaboration (Azure Storage backend for Terraform)
- **Use parameter files** for environment-specific configurations
- **Implement proper resource naming** following conventions: `dbw-{project}-{env}`, `{project}-{resource}-{env}-{deploymentid}`
- **Deploy Unity Catalog infrastructure** with external locations and storage credentials

### CI/CD Pipeline Strategy
- **Implement multi-stage pipelines** with separate build, test, and deploy phases
- **Use Databricks CLI and REST APIs** for workspace automation
- **Separate notebook deployment from package deployment** for better modularity
- **Include manual approval gates** for production deployments
- **Maintain environment parity** across dev/staging/production
- **Deploy Unity Catalog configurations** through automated pipelines

### Testing Strategy
- **Python unit tests** for data transformation logic separated into packages
- **Notebook integration tests** using nutter or pytest-databricks frameworks
- **Data quality validation** with Great Expectations integration
- **Performance testing** for Spark job optimization
- **Infrastructure validation** with automated deployment testing

### Environment Management
- **Maintain separate Unity Catalogs** per environment for proper isolation
- **Use Azure DevOps variable groups** for environment-specific settings
- **Implement proper secret management** with Azure Key Vault and Databricks secret scopes
- **Follow consistent naming conventions** across all environments
- **Configure compute policies** and cluster templates per environment

### Medallion Architecture Implementation
- **Bronze layer**: Raw data ingestion with Delta Lake format and timestamp partitioning
- **Silver layer**: Cleaned and validated data with Unity Catalog governance
- **Gold layer**: Business-ready dimensional models optimized for analytics workloads
- **Use Unity Catalog tables** for proper data governance and lineage tracking
- **Implement data lineage tracking** with Unity Catalog and Azure Purview integration
- **Configure external locations** for efficient data access across environments

## Security and Governance

### Unity Catalog Configuration
- **Deploy regional metastore** for centralized data governance
- **Configure storage credentials** with managed identities for secure access
- **Set up external locations** pointing to ADLS Gen2 containers
- **Implement catalog-per-environment** strategy for proper isolation
- **Configure proper permissions** at catalog, schema, and table levels
- **Enable audit logging** for all data access and governance operations

### Authentication and Authorization
- **Use service principals** for automated deployments and CI/CD operations
- **Implement Azure AD integration** with single sign-on for user access
- **Configure workspace-level permissions** appropriately (Admin, User, Contributor)
- **Secure connection strings** and tokens in Azure Key Vault
- **Use managed identities** where possible for Azure service authentication
- **Document security group assignments** and access patterns

### Data Governance
- **Implement data classification** using Unity Catalog tags and metadata
- **Enable comprehensive audit logging** for workspace activities and data access
- **Configure data lineage tracking** with Unity Catalog lineage capture
- **Establish data retention policies** aligned with compliance requirements
- **Document data sources and transformations** for regulatory compliance
- **Implement row-level and column-level security** where required

## Monitoring and Observability

### Application Insights Integration
- **Configure telemetry collection** for custom metrics and job performance monitoring
- **Implement custom dashboards** for operational visibility across environments
- **Set up alerting rules** for job failures and performance degradation
- **Monitor cluster utilization** and optimize resource allocation
- **Track deployment success rates** and pipeline performance metrics

### Log Management
- **Centralize log aggregation** using Log Analytics Workspace
- **Implement structured logging** in notebooks and Spark applications
- **Configure retention policies** for operational and audit logs
- **Create custom queries** for troubleshooting and performance analysis
- **Set up automated alerting** for error conditions and anomalies
- **Monitor Unity Catalog audit logs** for governance tracking

## Development Workflow

### Workspace Integration Best Practices
- **Connect workspace to Git repository** with proper branch strategy
- **Use feature branches** for development and pull requests for code review
- **Separate notebook development** from package development
- **Implement branch protection rules** to enforce code review and testing
- **Document workspace folder structure** and naming conventions
- **Use shared clusters** for development and dedicated clusters for production

### Code Organization
- **Separate infrastructure code** from application code in repository structure
- **Package data transformation logic** into Python wheels for reusability
- **Use consistent folder structure** across projects for maintainability
- **Implement code review processes** for all changes including notebooks
- **Version control all artifacts** including notebooks, configs, and libraries
- **Document Spark configurations** and cluster requirements

### Package Development
- **Extract business logic** into Python packages for better testability
- **Build and distribute packages** as wheels through CI/CD pipelines
- **Implement proper dependency management** with requirements.txt or poetry
- **Use semantic versioning** for package releases
- **Store packages** in Azure Artifacts or DBFS for distribution

## Performance Optimization

### Cluster Configuration
- **Right-size clusters** based on workload requirements and cost optimization
- **Configure auto-scaling policies** for dynamic workload handling
- **Use cluster policies** to enforce standards and control costs
- **Implement instance pools** for faster cluster startup times
- **Optimize Spark configurations** for specific workload patterns
- **Monitor cluster metrics** and adjust configurations based on usage

### Data Processing Optimization
- **Optimize Delta Lake file sizes** using optimize and z-order commands
- **Implement efficient partitioning** strategies based on query patterns
- **Use broadcast joins** and bucketing for large table optimizations
- **Configure adaptive query execution** for automatic optimization
- **Monitor query plans** and optimize based on execution patterns
- **Implement data caching** strategies for frequently accessed datasets

### Cost Optimization
- **Implement cluster auto-termination** policies to prevent idle resource costs
- **Use spot instances** where appropriate for cost-effective processing
- **Monitor DBU consumption** and optimize workload scheduling
- **Implement resource tagging** for cost allocation and tracking
- **Right-size instance types** based on actual workload requirements

## Troubleshooting Guidelines

### Common Issues and Solutions
- **Unity Catalog permissions**: Verify storage credentials and external location access
- **Cluster startup failures**: Check instance availability and cluster policies
- **Package import errors**: Verify wheel installation and Python path configuration
- **Performance issues**: Monitor Spark UI and optimize queries
- **Authentication failures**: Verify service principal permissions and token validity

### Diagnostic Tools
- **Use Spark UI** for query performance analysis and optimization
- **Leverage cluster logs** for startup and runtime issue diagnosis
- **Implement custom logging** in notebooks for detailed troubleshooting
- **Monitor Unity Catalog audit logs** for permission and access issues
- **Use Azure Monitor** for infrastructure-level diagnostics

### Error Handling Best Practices
- **Implement retry logic** for transient failures in data processing
- **Use dead letter queues** for failed message processing
- **Configure alerting** for critical job failures
- **Implement graceful degradation** for non-critical failures
- **Document known issues** and workarounds for team reference

## Data Quality and Validation

### Great Expectations Integration
- **Configure expectation suites** for each data layer (bronze, silver, gold)
- **Implement validation checkpoints** in data pipelines
- **Store validation results** in Azure Monitor for alerting
- **Generate data quality reports** automatically
- **Set up automated alerts** for data quality failures

### Schema Evolution
- **Implement schema evolution** strategies with Delta Lake
- **Use schema enforcement** to prevent data corruption
- **Document schema changes** and impact analysis
- **Implement backward compatibility** testing for schema changes
- **Configure schema validation** in CI/CD pipelines

## Compliance and Auditing

### Regulatory Requirements
- **Implement data residency** controls using Unity Catalog governance
- **Configure comprehensive audit trails** for all data operations
- **Document data processing activities** for compliance reporting
- **Implement data subject rights** processes (GDPR, CCPA compliance)
- **Maintain security certifications** and compliance documentation

### Documentation Standards
- **Document all architectural decisions** with rationale and alternatives
- **Maintain runbooks** for operational procedures and incident response
- **Document data lineage** and transformation logic comprehensively
- **Keep security procedures** current with evolving threat landscape
- **Document disaster recovery** and business continuity procedures

## Team Collaboration

### Knowledge Sharing
- **Implement code review processes** for all changes including infrastructure
- **Document best practices** and lessons learned from implementations
- **Conduct regular architecture reviews** to ensure alignment with standards
- **Share reusable components** and utilities across teams
- **Maintain technical documentation** current with implementation changes

### Training and Development
- **Provide training** on Databricks capabilities and Unity Catalog features
- **Establish mentoring programs** for team members new to the platform
- **Encourage experimentation** with new features in development environments
- **Share knowledge** through internal presentations and documentation
- **Stay current** with Databricks updates and new capabilities

### Workspace Management
- **Implement workspace organization** standards for folders and naming
- **Configure shared compute policies** for consistent environments
- **Establish notebook development** guidelines and best practices
- **Document cluster configuration** standards and requirements
- **Implement workspace-level** governance and access controls

---

*This guidance is based on proven patterns from enterprise Databricks implementations and should be adapted to your organization's specific requirements and constraints.*
