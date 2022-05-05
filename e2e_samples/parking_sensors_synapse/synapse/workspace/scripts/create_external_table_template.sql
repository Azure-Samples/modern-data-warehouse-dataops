-- CREATE DATABASE
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'external_db')
BEGIN
    CREATE DATABASE external_db
END
GO
USE external_db
-- Create MASTER KEY 
IF NOT EXISTS
    (SELECT * FROM sys.symmetric_keys
        WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY
END
GO
-- Create Database Scope Credential [Managed Identity]
IF NOT EXISTS
    (SELECT * FROM sys.database_scoped_credentials
         WHERE name = 'SynapseIdentity')
    CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity
    WITH IDENTITY = 'Managed Identity'
GO
IF NOT EXISTS
    (SELECT * FROM sys.database_scoped_credentials
         WHERE name = 'WorkspaceIdentity')
    CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
    WITH IDENTITY = 'Managed Identity'
GO
-- Create Parquet Format [SynapseParquetFormat]
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat')
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat]
	WITH ( FORMAT_TYPE = parquet)
GO
-- DROP EXTERNAL DATA SOURCE INTERIM_Zone
-- Create External Data Source
IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'INTERIM_Zone')
	CREATE EXTERNAL DATA SOURCE INTERIM_Zone
	WITH (  LOCATION   =  'https://<data storage account>.dfs.core.windows.net/datalake/data/interim/'
    ,CREDENTIAL = WorkspaceIdentity )
Go
-- Create parking_bay View 
IF EXISTS(select * FROM sys.views where name = 'parking_bay_view')
    DROP VIEW IF EXISTS parking_bay_view;
GO
CREATE VIEW parking_bay_view AS
SELECT * 
FROM OPENROWSET(
        BULK 'interim.parking_bay/*.parquet',
        DATA_SOURCE = 'INTERIM_Zone',
        FORMAT = 'PARQUET'
    )
AS [r];
GO
-- Create sensor View 
IF EXISTS(select * FROM sys.views where name = 'sensor_view')
    DROP VIEW IF EXISTS sensor_view;
GO
CREATE VIEW sensor_view AS
SELECT * 
FROM OPENROWSET(
        BULK 'interim.sensor/*.parquet',
        DATA_SOURCE = 'INTERIM_Zone',
        FORMAT = 'PARQUET'
    )
AS [r];
GO