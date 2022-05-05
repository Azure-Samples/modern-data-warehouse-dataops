/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

:setvar ADLSLocation ADLSLocation
:setvar ADLSCredentialKey ADLSCredentialKey

ALTER EXTERNAL DATA SOURCE [AzureDataLakeStorage] SET LOCATION = '$(ADLSLocation)';
GO

ALTER DATABASE SCOPED CREDENTIAL [ADLSCredentialKey] WITH IDENTITY = N'user', SECRET = '$(ADLSCredentialKey)';  
GO 
