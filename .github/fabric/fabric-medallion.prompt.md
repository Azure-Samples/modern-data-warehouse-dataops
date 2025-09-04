# Fabric Medallion Architecture Implementation

Use this prompt to guide the implementation of a robust medallion architecture in Microsoft Fabric, following enterprise best practices and proven patterns.

---

**Prompt for GitHub Copilot:**

You are a Microsoft Fabric data architecture expert specializing in medallion architecture implementations. Help me design and implement a medallion architecture for my data platform that follows enterprise best practices and proven patterns from production deployments.

## Architecture Overview Request

Please help me implement a medallion architecture with the following layers:

### Bronze Layer (Raw Data Ingestion)
Design the bronze layer to handle raw data ingestion with these requirements:

**Data Sources**: [Describe your data sources - databases, APIs, files, streaming data, etc.]
**Data Volume**: [Specify expected data volumes - GB/TB per day, records per second, etc.]
**Data Formats**: [List formats - JSON, CSV, Parquet, Avro, etc.]
**Ingestion Frequency**: [Specify - real-time, hourly, daily, etc.]

**Implementation Patterns**:
- Use **Fabric data pipelines** for scheduled and event-driven ingestion
- Store raw data in **lakehouse Files section** with timestamp-based folder structure:
  ```
  Files/
  ├── bronze/
  │   ├── source_system_1/
  │   │   ├── table_name/
  │   │   │   ├── year=2024/month=01/day=15/hour=14/
  │   │   │   │   └── data_file.parquet
  ```
- Implement **data validation and schema enforcement** at ingestion point
- Create **shortcuts to external data sources** for efficient access without data movement
- Configure **error handling and dead letter queues** for failed ingestion attempts

### Silver Layer (Cleaned and Validated Data)
Design the silver layer for data cleansing and business rule application:

**Data Quality Requirements**: [Specify quality rules, validation requirements, etc.]
**Business Rules**: [Describe transformation logic, calculations, etc.]
**Data Lineage**: [Requirements for tracking data transformations]

**Implementation Patterns**:
- Apply **data quality rules and cleansing logic** using Fabric notebooks
- Use **Delta tables** in lakehouse Tables section for ACID transactions and time travel
- Implement **schema evolution** handling for changing source systems
- Create **data validation pipelines** with quality metrics and monitoring
- Store cleaned data with **standardized schemas** and **consistent naming conventions**:
  ```
  Tables/
  ├── silver/
  │   ├── dim_customer/
  │   ├── dim_product/
  │   ├── fact_sales/
  │   └── fact_inventory/
  ```
- Implement **data lineage tracking** with Microsoft Purview integration
- Configure **automated data quality monitoring** with alerts

### Gold Layer (Business-Ready Analytics)
Design the gold layer for consumption-ready data:

**Analytics Requirements**: [Specify reporting, ML, API serving needs]
**Performance Requirements**: [Query patterns, latency requirements, concurrency]
**Security Requirements**: [Access controls, data masking, compliance needs]

**Implementation Patterns**:
- Create **dimensional models and aggregated views** optimized for analytics
- Use **semantic models** for Power BI integration and self-service analytics
- Implement **role-based security** and **row-level security** where needed
- Create **optimized materialized views** for frequent query patterns
- Structure for consumption:
  ```
  Tables/
  ├── gold/
  │   ├── marts/
  │   │   ├── sales/
  │   │   ├── marketing/
  │   │   └── finance/
  │   ├── aggregates/
  │   │   ├── daily_sales_summary/
  │   │   └── monthly_kpis/
  ```
- Apply **data governance policies** and **sensitivity labels**
- Implement **audit logging** for data access and usage

## Specific Implementation Guidance

### 1. Lakehouse Design and Organization
Please provide guidance on:
- **Folder structure** for optimal organization and performance
- **Partitioning strategies** based on my query patterns: [Describe typical queries]
- **File format optimization** (Delta, Parquet) for storage and performance
- **Shortcut configuration** for external data sources
- **Security model** implementation across layers

### 2. Data Pipeline Architecture
Design data pipelines that include:
- **Source-to-Bronze** pipelines for each data source
- **Bronze-to-Silver** transformation pipelines with quality checks
- **Silver-to-Gold** aggregation and modeling pipelines
- **Error handling and retry logic** for robust operation
- **Monitoring and alerting** for pipeline health

### 3. Notebook Development Patterns
Create notebook templates for:
- **Data validation and quality checks** with standard patterns
- **Schema inference and evolution** handling
- **Data transformation utilities** and common functions
- **Logging and monitoring** integration
- **Unit testing patterns** for notebook logic

### 4. Configuration Management
Implement configuration management for:
- **Environment-specific parameters** (dev/staging/prod)
- **Data source connection strings** and authentication
- **Pipeline schedules and dependencies** configuration
- **Quality thresholds and business rules** parameters
- **Security policies and access controls** definitions

### 5. Testing Strategy
Develop testing approaches for:
- **Data quality validation** at each layer
- **Pipeline integration testing** with sample data
- **Performance testing** for scalability validation
- **Schema change impact** testing
- **End-to-end business logic** validation

## Questions to Guide Implementation

Please ask me about:

1. **Data Sources and Volume**:
   - What are your primary data sources (databases, APIs, files, streaming)?
   - What are the expected data volumes and growth patterns?
   - What are the ingestion frequency requirements (real-time, batch, hybrid)?
   - Are there specific compliance or governance requirements?

2. **Business Requirements**:
   - What are the key business questions you need to answer?
   - Who are the primary consumers of the data (analysts, data scientists, applications)?
   - What are the performance and latency requirements?
   - Are there specific data retention requirements?

3. **Technical Constraints**:
   - Do you have existing data infrastructure to integrate with?
   - What are your preferred development tools and languages?
   - Are there specific security or compliance requirements?
   - What is your team's experience level with Fabric and data engineering?

4. **Operational Requirements**:
   - What are your monitoring and alerting needs?
   - How do you handle data quality issues and errors?
   - What are your backup and disaster recovery requirements?
   - How do you manage configuration changes across environments?

## Deliverables Requested

Based on my answers, please provide:

1. **Architecture Diagram**: Visual representation of the medallion architecture
2. **Lakehouse Structure**: Detailed folder and table organization
3. **Pipeline Definitions**: Data pipeline configurations and dependencies
4. **Notebook Templates**: Reusable patterns for common operations
5. **Configuration Files**: Environment and parameter management
6. **Testing Framework**: Unit and integration test patterns
7. **Monitoring Setup**: Observability and alerting configuration
8. **Documentation**: Implementation guide and operational runbooks

## Implementation Checklist

Create a checklist covering:
- [ ] **Lakehouse creation** with proper folder structure
- [ ] **Data source connections** and authentication setup
- [ ] **Bronze layer pipelines** for data ingestion
- [ ] **Silver layer transformations** with quality checks
- [ ] **Gold layer modeling** and optimization
- [ ] **Semantic model creation** for analytics consumption
- [ ] **Security implementation** with proper access controls
- [ ] **Testing framework** setup and validation
- [ ] **Monitoring and alerting** configuration
- [ ] **Documentation** and runbook creation
- [ ] **CI/CD pipeline** integration
- [ ] **Performance optimization** and tuning

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Provide specific details about your data sources, requirements, and constraints
3. Review the generated architecture and implementation guidance
4. Customize the patterns for your specific use case and organizational requirements
5. Follow the implementation checklist to ensure complete setup

**Note**: This prompt is designed to work with the broader DataOps patterns and can be combined with other Copilot artifacts for infrastructure setup, CI/CD implementation, and testing strategies.
