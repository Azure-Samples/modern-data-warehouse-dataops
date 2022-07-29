-- DROP EXTERNAL DATA SOURCE INTERIM_Zone
-- Create External Data Source
--https://mdwdopsstdevimops.dfs.core.windows.net/datalake/data/interim/
--declare @ADLSLocation varchar(300)
--set @ADLSLocation = 'https://mdwdopsstdevimops.dfs.core.windows.net/datalake/data/interim/'

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'INTERIM_Zone')
	CREATE EXTERNAL DATA SOURCE INTERIM_Zone
	WITH (  LOCATION   =  N'$(ADLSLocation)'
    ,CREDENTIAL = WorkspaceIdentity )
Go