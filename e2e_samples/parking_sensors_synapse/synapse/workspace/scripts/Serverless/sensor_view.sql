-- Create sensor View now with variables
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
WITH (
    [bay_id] BIGINT 
    ,[st_marker_id] VARCHAR(100)
    ,[lat] REAL
    ,[lon] REAL
    ,[location] VARCHAR(300)
    ,[status] VARCHAR(10)
    ,[load_id] VARCHAR(100)
    ,[loaded_on] VARCHAR(200)
)
AS [r];
GO