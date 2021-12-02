USE master
-- CREATE SQL LOGIN USER  WITH PASSWORD 
IF NOT EXISTS(SELECT name FROM sys.server_principals WHERE name = '<your sql login user name>')
BEGIN
    CREATE LOGIN [<your sql login user name>] WITH PASSWORD = '<your password>'
END
GO
-- CREATE DATABASE
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '<your database name>')
BEGIN
    CREATE DATABASE [<your database name>]
END
GO
USE <your database name> 
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
-- CREATE DB USER NAME
IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = '<your db user name>')
BEGIN
    CREATE USER [<your db user name>] 
    FOR LOGIN [<your sql login user name>] 
    WITH DEFAULT_SCHEMA = dbo; 
END
GO
-- GRANT DB ROLES TO USER
ALTER ROLE db_datareader ADD MEMBER [<your db user name>]; 
ALTER ROLE db_datawriter ADD MEMBER [<your db user name>]; 
GO
-- grant user CREDENTIAL
-- enable users to reference that credential so they can access storage.
grant references 
    on database scoped credential::SynapseIdentity
    to  [<your db user name>]; 
-- grant CONTROL on Database 
GRANT CONTROL ON DATABASE SCOPED CREDENTIAL::SynapseIdentity TO  [<your db user name>]
GO
GRANT CONTROL ON DATABASE::<your database name> to  [<your db user name>];
-- Note: the CONTROL permission includes such permissions as INSERT, UPDATE, DELETE, EXECUTE, and several others.  
GO