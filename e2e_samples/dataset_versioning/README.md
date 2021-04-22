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
    1. Provision infra with terraform - [detailed steps](./infra/README.md)
    1. **[Need update]** Add user permission (Credential passthough)
    1. Create table and install stored procedure - [detailed steps](./datafactory/config/README.md)
    1. Deploy application logic (ARM templates) for Data Factory - [detailed steps](./datafactory/README.md)
1. Functional test
    1. Load data into data source (Azure SQL Database)
        1. Use Python script to load "LendingClub issued Loans" data - [detailed steps](./insert_sql/README.md)
    1. Run Azure Data Factory pipeline to load Delta Lake
        1. Go to provisioned Azure Data Factory, then click [Author & Monitor] button to open development portal.
        1. Click pencil button at left pane, then select [DeltaCopyPipeline].
        1. Cick [Debug] button to run pipeline.
    1. Use Databricks to query Delta versions
        1. Go to Azure Databricks and create a cluster. Remember to tick the "enable credential passthrough" check under the advanced settings if you plan to use the credential passthrough feature. Make sure you have access to Deltalake either with a RBAC role or Access Control List. [detailed steps](./databricks/README.md)
        1. Create a notebook in Azure Databricks. Select your cluster and execute these scripts below:
            ```python
            # For credential passthrough
            configs = {
                "fs.azure.account.auth.type": "CustomAccessToken",
                "fs.azure.account.custom.token.provider.class": spark.conf.get("spark.databricks.passthrough.adls.gen2.tokenProviderClassName")
            }
            ```
            ```python
            # Confirm if you can access deltalake. Update the path with the name of your storage account.
            file_path = "abfss://datalake@{your_storage_account_name}.dfs.core.windows.net/lc_loan"
            dbutils.fs.ls(file_path)
            ```
            ```python
            # List versions
            spark.sql(f"DESCRIBE HISTORY delta.`{file_path}`").show()
            
            # Load from specific version
            load_data = spark.read.format("delta").option("versionAsOf", 0).load(file_path)
            load_data.show()
            ```
    1. Repeat previous steps to see multiple versioned data.
        1. Insert next version of data (ex. version 1) ```python main.py -v 1 -k https://sample.vault.azure.net -p ./lc_loan.csv```
        1. Run Azure Data Factory pipeline
        1. Run Notebook to see version 1 on DataBricks
1. Clean up
    1. Run `terraform destroy` to clean up existing resources. You can delete resource group manually on Azure Portal/Azure CLI.