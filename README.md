---
page_type: sample
languages:
- python
- C#
products:
- Azure
- Azure-Data-factory
- Azure-Databricks
- Azure-Data-Lake-Gen2
- Azure-Functions
description: "Code samples showcasing how to apply DevOps concepts to the Modern Data Warehouse Architecture leveraging different Azure Data Technologies."
---

# DataOps for the Modern Data Warehouse

This repository contains numerous code samples and artifacts on how to apply DevOps principles to data pipelines built according to the [Modern Data Warehouse (MDW)](https://azure.microsoft.com/en-au/solutions/architecture/modern-data-warehouse/) architectural pattern on [Microsoft Azure](https://azure.microsoft.com/en-au/).

The samples are either focused on a single azure service or showcases an end to end data pipeline solution built according to the MDW pattern. Each sample contains code and artifacts relating to:

- Build and Release Pipelines (CI/CD)
- Testing
- Observability / Monitoring

## Contents

### End to End samples

- [**Parking Sensor Solution**](e2e_samples/parking_sensors/) - This demonstrates batch, end-to-end data pipeline following the MDW architecture, along with a corresponding CI/CD process. See [here](https://www.youtube.com/watch?v=Xs1-OU5cmsw) for the presentation which includes a detailed walk-through of the solution.
  - *Technology stack*: Azure DevOps, Azure Data Factory, Azure Databricks, Azure Synapse and ADLS Gen2.
- [**Temperature Events Solution**](e2e_samples/temperature_events) - This demonstrate a high-scale event-driven data pipeline with a focus on how to implement Observability and Load Testing.
  - *Technology stack*: Azure DevOps, Azure Functions, Terraform, Application Insights, Azure Eventhubs
- [**MDW Data Governance and PII data detection**](e2e_samples/mdw_governance) - This sample demonstrates how to deploy the Infrastructure of an end-to-end MDW Pipeline using [Azure DevOps pipelines](https://azure.microsoft.com/en-au/services/devops/pipelines/) along with a particular focus around Data Governance and PII data detection.
  - *Technology stack*: Azure DevOps, Azure Data Factory, Azure Purview

### Single Technology Samples

- [Azure SQL](single_tech_samples/azuresql/)
- [Data Factory](single_tech_samples/datafactory/)

#### Coming soon

- [Azure Databricks](single_tech_samples/databricks/)
- [Stream Analytics](single_tech_samples/streamanalytics/)
- [Azure Synapse (formerly SQLDW)](single_tech_samples/synapseanalytics/)
- [CosmosDB](single_tech_samples/cosmosdb/)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
