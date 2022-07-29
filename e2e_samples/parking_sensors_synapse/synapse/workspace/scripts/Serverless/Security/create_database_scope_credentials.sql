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