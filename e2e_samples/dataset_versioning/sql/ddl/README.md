# Azure SQL Database Object Definitions

This folder is for SQL query which creates the following required tables and stored procedures.

- `source` table which stores sample data
- `WaterMark` table storing table name and its watermark value
- `usp_UpdateWatermark` stored procedure to update watermark value

## Prerequisites

- [Provisioned Azure Resources by IaC (Terraform)](../../infra/README.md)

## Setup and Deployment

1. Retrieve AzureSQL connection string including the user id and password from KeyVault.
   1. In the Azure Portal, navigate to provisioned resource group.
   1. Select the provisioned KeyVault.
   1. Click [Secrets] in left pane to see all secrets
   1. Click `watermarkdb-connection` secret.
   1. Click current version, then click [Show Secret Value] button. You can see connection string of SQL Database.
   1. Connection string includes user id and password, so please copy them to notepad for future steps.
1. [Whitelist your IP address in Azure SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure#use-the-azure-portal-to-manage-server-level-ip-firewall-rules).
1. Navigate to AzureSQL Database instance and select Query Editor (preview). Run the `./config/watermark.sql`.

## Next step

[Deploy Data Factory Pipelines](../../datafactory/README.md)
