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
WITH ( 
 [bay_id] BIGINT
,[last_edit] VARCHAR(50)
,[marker_id] VARCHAR(50)
,[meter_id] VARCHAR(50)
,[rd_seg_dsc] VARCHAR(500)
,[rd_seg_id] VARCHAR(50)
,[the_geom] VARCHAR(MAX)
,[load_id] VARCHAR(50)
,[loaded_on] VARCHAR(50))
AS [r];
GO