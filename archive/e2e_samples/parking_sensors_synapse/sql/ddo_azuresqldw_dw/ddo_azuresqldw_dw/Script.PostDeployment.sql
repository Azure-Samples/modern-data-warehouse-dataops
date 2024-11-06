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
IF NOT EXISTS (SELECT 1 FROM dbo.dim_date)
BEGIN
    PRINT '******Seeding dim_date table******';
    EXEC dbo.load_dim_date;
END

IF NOT EXISTS (SELECT 1 FROM dbo.dim_time)
BEGIN
    PRINT '******Seeding dim_time table******';
    EXEC dbo.load_dim_time;
END