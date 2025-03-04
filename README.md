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

In addition to the samples, this repository also contains [Utilities](#utilities). These are simple scripts or code snippets that can be used as-is or as a starting point for more complex automation tasks.

## Single-Technology Samples

| Technology | Samples |
| ---------- | ------- |
| [Microsoft Fabric](./single_tech_samples/fabric/README.md) | ▪️ [CI/CD for Microsoft Fabric](./single_tech_samples/fabric/fabric_ci_cd/README.md)<br> ▪️ [Feature engineering on Microsoft Fabric](./single_tech_samples/fabric/feature_engineering_on_fabric/README.md) |
| [Azure SQL database](./single_tech_samples/azuresql/README.md) | ▪️ [CI/CD for Azure SQL database](./single_tech_samples/azuresql/azuresql_ci_cd/README.md) |
| [Azure Data Factory](./single_tech_samples/datafactory/README.md) | ▪️ [CI/CD for ADF with Auto publish](./single_tech_samples/datafactory/adf_cicd_auto_publish/README.md)<br> ▪️ [Data pre-processing using Azure Batch](./single_tech_samples/datafactory/adf_data_pre_processing_with_azure_batch/README.md) |
| [Azure Stream Analytics](./single_tech_samples/streamanalytics/README.md) | ▪️ [CI/CD for Azure Stream Analytics](./single_tech_samples/streamanalytics/streamanalytics_ci_cd/README.md) |

## End-to-End Samples

### DataOps for Medallion with Azure Data Factory and Azure Databricks

This [sample](e2e_samples/parking_sensors/) demonstrates batch, end-to-end data pipeline utilizing Azure Data Factory and Azure Databricks built according to the [medallion architecture](https://learn.microsoft.com/azure/databricks/lakehouse/medallion), along with a corresponding CI/CD process, observability and automated testing.

[![Medallion with Azure Data Factory and Azure Databricks](docs/images/CI_CD_process_simplified.png "Architecture")](e2e_samples/parking_sensors/)

### DataOps for Medallion with Microsoft Fabric

- This [sample](./e2e_samples/fabric_dataops_sample/) would demonstrate end-to-end batch data processing utilizing Microsoft Fabric built according to the [medallion architecture](https://learn.microsoft.com/azure/databricks/lakehouse/medallion), along with a corresponding CI/CD process, observability and automated testing.

  In the current version, the sample is showcasing the deployment of Azure and Fabric resources together using Terraform. The deployment uses a service principal or managed identity for authentication where supported and falls back to Entra user authentication where it is not.

## Utilities

| Technology | Utility Description |
| ---------- | ------------------- |
| Microsoft Fabric | ▪️ [Script to upload file in GIT repo to Fabric lakehouse](./utilities/fabric/README.md#python-script-to-upload-file-in-git-repo-to-fabric-lakehouse)|

## Contributing

This project welcomes contributions and suggestions. Please see our [Contributing guide](/CONTRIBUTING.md).

## Important Notice Concerning Financial and Performance Information from the Microsoft Investor Relations Website
Certain financial and other information on the Investor Relations website is reproduced or derived from more comprehensive information contained in our quarterly earnings releases and periodic reports and other filings with the Securities and Exchange Commission. The information contained on the Investor Relations website is unaudited unless otherwise noted or accompanied by an audit opinion and is not intended as a substitute for, and should be read in the context of, the more comprehensive information contained in these other documents. In the event of any conflict, the information contained in our quarterly earnings releases and our periodic reports and filings with the SEC shall take precedence.
 
The Investor Relations website, including without limitation the “Outlook” portion of the "Earnings and Financials" section, may contain information from third parties. Examples, include estimates of future performance or hyperlinks to third party websites. This information does not represent opinions, forecasts, or factual assertions of Microsoft and we do not endorse it by including it in this website.
 
 
All information on this website speaks only as of
 
- the last fiscal quarter or year for which we have filed a Form 10-Q or 10-K or,
- for historical information, the date or period expressly indicated in or with such information.
 
We undertake no duty to update this information or any information provided by third parties.
 
Certain statements on this site, including those in the “Outlook” portion of this site, are "forward-looking statements" and are based on our expectations and assumptions as of the date the statement was made. Our actual results could differ materially from those described in these forward-looking statements because of risks and uncertainties. These risks and uncertainties are described in our quarterly earnings releases and in the “Management’s Discussion and Analysis of Financial Condition and Results of Operations” and “Risk Factors” sections of our periodic reports and filings with the SEC. Copies of our SEC reports may be obtained by contacting our Investor Relations department at (800) 285-7772 or by clicking [here](https://www.microsoft.com/en-us/investor/sec-filings).
