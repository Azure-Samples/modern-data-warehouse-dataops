# DataOps - Dataset versioning demo

This sample demonstrates how to use a data pipeline to copy versioned data into Data Lake.

## Story

Contoso provides ML based loan prediction feature to end users. For keeping end-user experience, they want to keep updating ML model with latest data. It helps Contoso to keep end user satisfaction high and subscription-based contract.

For achieving it, data scientists (DS) asks data engineers to save multiple-version data (ex. v0 data is saved in 2020, v1 data is saved in 2021). It helps DS to manage data and trained model. For saving cost, data engineers want to copy data with shorter duration.

## Solution overview

The solution demonstrates how to achieve the requirements described above by:

- Data Pipeline (Azure Data Factory) copy **versioned data** from source to sink
- DS can read versioned data from Data Bricks. They can specify version number when they load data from Delta Lake.
- Data pipeline utilizes a watermark to see new/updated data in the data source. It helps to **copy data with shorter duration**.
- Terraform helps enginners to provision expected infrastructure.
- Local python script inject data to data source (SQL Database) incrementally, so that you can simulate data source update(ex. you can inject 2020 data at first, then inject 2021 data to data source).

![architecture](./docs/images/architecture.PNG)

### Data we use

We refer to [LendingClub issued Loans](https://www.kaggle.com/husainsb/lendingclub-issued-loans?select=lc_loan.csv) data hosted by Kaggle.

### How to use the sample

1. Setup Infra
    1. **[Need update]** Run terraform
    1. **[Need update]** Add user permission (Credential passthough)
    1. Create table and install stored procedure - [detailed steps](./datafactory/config/README.md)
    1. Deploy application logic (ARM templates) for Data Factory - [detailed steps](./datafactory/README.md)
1. Load data into data source (Azure SQL Database)
    1. Use Python script to load "LendingClub issued Loans" data - [detailed steps](./insert_sql/README.md)
1. Functional test
    1. Run Azure Data Factory pipeline to load Delta Lake
        1. Go to provisioned Azure Data Factory, then click [Author & Monitor] button to open development portal.
        1. Click pencil button at left pane, then select [DeltaCopyPipeline].
        1. Cick [Debug] button to run pipeline.
    1. **[Need update]** Use Databricks to query Delta versions
    1. **[Need update]** Run Python script to incrementally load
1. **[Need update]**
