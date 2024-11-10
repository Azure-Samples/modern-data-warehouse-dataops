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
description: "Code samples showcasing how to apply DevOps concepts to common data engineering patterns and architectures leveraging different Microsoft data platform technologies."
---

# DataOps

This repository contains numerous code samples and artifacts on how to apply DevOps principles to common data engineering patterns and architectures utilizing Microsoft data platform technologies.

The samples are either focused on a single microsoft service ([Single-Technology Samples](#single-technology-samples)) or showcases an end-to-end data pipeline solution as a reference implementation ([End-to-End Samples](#end-to-end-samples)). Each sample contains code and artifacts related to one or more of the following capabilities:

- Infrastructure as Code (IaC)
- Build and Release Pipelines (CI/CD)
- Testing
- Observability / Monitoring

In addition to the samples, this repository also contains [Utilities](#utilities). These are simple script or code snippets that can be used as-is or as a starting point for more complex automation tasks.

## Single-Technology Samples

| Technology | Samples |
| ---------- | ------- |
| [Microsoft Fabric](./single_tech_samples/fabric/README.md) | ▪️ [CI/CD for Microsoft Fabric](./single_tech_samples/fabric/fabric_ci_cd/README.md)<br> ▪️ [Feature engineering on Microsoft Fabric](./single_tech_samples/fabric/feature_engineering_on_fabric/README.md) |
| [Azure SQL database](./single_tech_samples/azuresql/README.md) | ▪️ [CI/CD for Azure SQL database](./single_tech_samples/azuresql/azuresql_ci_cd/README.md) |
| [Azure Databricks](single_tech_samples/databricks/) | ▪️ [CI/CD for Azure Databricks](single_tech_samples/databricks/databricks_ci_cd/README.md) |
| [Azure Data Factory](./single_tech_samples/datafactory/README.md) | ▪️ [CI/CD for ADF with Auto publish](./single_tech_samples/datafactory/adf_cicd_auto_publish/README.md)<br> ▪️ [Data pre-processing using Azure Batch](./single_tech_samples/datafactory/adf_data_pre_processing_with_azure_batch/README.md) |
| [Azure Stream Analytics](./single_tech_samples/streamanalytics/README.md) | ▪️ [CI/CD for Azure Stream Analytics](./single_tech_samples/streamanalytics/streamanalytics_ci_cd/README.md) |

## End-to-End Samples

### DataOps for Medallion with Azure Data Factory and Azure Databricks

This [sample](e2e_samples/parking_sensors/) demonstrates batch, end-to-end data pipeline utilizing Azure Data Factory and Azure Databricks built according to the [medallion architecture](https://learn.microsoft.com/en-us/azure/databricks/lakehouse/medallion), along with a corresponding CI/CD process, observability and automated testing.

[![Medallion with Azure Data Factory and Azure Databricks](docs/images/CI_CD_process_simplified.png "Architecture")](e2e_samples/parking_sensors/)

### DataOps for Medallion with Microsoft Fabric

- Coming soon.

## Utilities

| Technology | Utility Description |
| ---------- | ------------------- |
| Microsoft Fabric | ▪️ [Script to upload file in GIT repo to Fabric lakehouse](./utilities/fabric/README.md#python-script-to-upload-file-in-git-repo-to-fabric-lakehouse)|

## Contributing

This project welcomes contributions and suggestions. Please see our [Contributing guide](/CONTRIBUTING.md).
