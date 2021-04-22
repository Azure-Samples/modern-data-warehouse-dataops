# Overview

This folder is for SQL query which creata following required tables and stored procedures.

- `source` table which stores sample data
- `WaterMark` table storing table name and its watermark value
- `usp_UpdateWatermark` stored procedure to update watermark value

## How to create required tables and stored procedure

1. Install [Azure Data Studio](https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver15)
1. Get user id and connection string for SQL Database
   1. Sign-in to Azure and go to provisioned resource group.
   1. Go to Azure KeyVault
   1. Click [Access policies] in left pane, then click [+ Add Access Policy]
   1. Click [Secret permissions] dropbox, then check [Select all] check box.
   1. Click [None selected], then add yourself. Click [Add] to save setting.
   1. Click [Secrets] in left pane, then click [watermarkdb-connection].
   1. Click current version, then click [Show Secret Value] to see connection string.
   1. You can get user id and password from it.
1. [Allow your ip address in SQL Database page](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure#use-the-azure-portal-to-manage-server-level-ip-firewall-rules).
1. Launch Azure Data Studio, then connect to SQL Database.
1. Copy query in `./config/watermark.sql` into Azure Data Studio, then run it.
