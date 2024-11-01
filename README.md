---
page_type: sample
languages:
- python
- csharp
- typeScript
- bicep
products:
- azure
- microsoft-fabric
- azure-sql-database
- azure-data-factory
- azure-databricks
- azure-stream-analytics
- azure-synapse-analytics
description: "Code samples showcasing how to apply DevOps concepts to the modern data warehouse architecture leveraging different Azure data technologies."
---

# DataOps for the Modern Data Warehouse

This repository contains numerous code samples and artifacts on how to apply DevOps principles to data pipelines built according to the [Modern Data Warehouse (MDW)](https://learn.microsoft.com/en-au/azure/architecture/solution-ideas/articles/enterprise-data-warehouse) architectural pattern on Microsoft Azure.

The samples are either focused on a single azure service (**Single Tech Samples**) or showcases an end to end data pipeline solution as a reference implementation (**End to End Samples**). Each sample contains code and artifacts relating one or more of the following

- Infrastructure as Code (IaC)
- Build and Release Pipelines (CI/CD)
- Testing
- Observability / Monitoring

## Single Technology Samples

- [Microsoft Fabric](./single_tech_samples/fabric/README.md)
  - [CI/CD - Microsoft Fabric](./single_tech_samples/fabric/fabric_ci_cd/README.md)
  - [Feature engineering on Microsoft Fabric](./single_tech_samples/fabric/feature_engineering_on_fabric/README.md)
- [Azure SQL database](./single_tech_samples/azuresql/README.md)
  - [CI/CD - Azure SQL database](./single_tech_samples/azuresql/azuresql_ci_cd/README.md)
- [Azure Databricks](single_tech_samples/databricks/)
  - [IaC - Basic deployment](single_tech_samples/databricks/databricks_ci_cd/README.md)
- [Azure Data Factory](./single_tech_samples/datafactory/README.md)
  - [CI/CD - Auto publish](./single_tech_samples/datafactory/adf_cicd_auto_publish/README.md)
  - [Data pre-processing using Azure Batch](./single_tech_samples/datafactory/adf_data_pre_processing_with_azure_batch/README.md)
- [Azure Synapse Analytics](./single_tech_samples/synapseanalytics/README.md)
  - [Serverless best practices](./single_tech_samples/synapseanalytics/synapse_serverless/README.md)
- [Azure Stream Analytics](./single_tech_samples/streamanalytics/README.md)
  - [CI/CD - Azure Stream Analytics](./single_tech_samples/streamanalytics/streamanalytics_ci_cd/README.md)

## End to End samples

### Parking Sensor Solution

This demonstrates batch, end-to-end data pipeline following the MDW architecture, along with a corresponding CI/CD process.

![Architecture](docs/images/CI_CD_process_simplified.png?raw=true "Architecture")

This has two version of the solution:

- [Azure Data Factory and Azure Databricks Version](e2e_samples/parking_sensors/)
- [Azure Synapse Version](e2e_samples/parking_sensors_synapse/)

## Contributing

This project welcomes contributions and suggestions. Please see our [Contributing guide](/CONTRIBUTING.md).
