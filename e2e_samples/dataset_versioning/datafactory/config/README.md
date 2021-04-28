# Overview

This folder is for SQL query which creata following required tables and stored procedures.

- `source` table which stores sample data
- `WaterMark` table storing table name and its watermark value
- `usp_UpdateWatermark` stored procedure to update watermark value

## Prerequistics

- Basic knowledge to use Azure Data Studio. You can refer [this document](https://docs.microsoft.com/en-us/sql/azure-data-studio/quickstart-sql-server?view=sql-server-ver15).

## How to create required tables and stored procedure

1. Install [Azure Data Studio](https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver15)
1. Get user id and password of SQL Database. Will use it when you connect to SQL Database with Azure Data Studio.
   1. Sign-in to Azure and go to provisioned resource group.
   1. Go to Azure KeyVault.
   1. Click [Secrets] in left pane to see all secrets
   1. Click "watermarkdb-connection" secret.
   1. Click current version, then click [Show Secret Value] button. You can see connection string of SQL Database.
   1. Connection string includes user id and password, so please copy them to notepad for future steps.
1. [Allow your ip address in SQL Database page](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure#use-the-azure-portal-to-manage-server-level-ip-firewall-rules).
1. Launch Azure Data Studio, then connect to SQL Database with user id and password which you get in previous step.
1. Copy query in `./config/watermark.sql` into Azure Data Studio, then run it.
