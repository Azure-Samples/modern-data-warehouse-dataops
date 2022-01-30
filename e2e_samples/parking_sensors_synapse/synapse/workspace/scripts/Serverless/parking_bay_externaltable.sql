SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[parking_bay_ext]
(
 [bay_id] BIGINT
,[last_edit] VARCHAR(50)
,[marker_id] VARCHAR(50)
,[meter_id] VARCHAR(50)
,[rd_seg_dsc] VARCHAR(500)
,[rd_seg_id] VARCHAR(50)
,[the_geom] VARCHAR(MAX)
,[load_id] VARCHAR(50)
,[loaded_on] VARCHAR(50)
)
WITH (DATA_SOURCE = [INTERIM_Zone],LOCATION = N'interim.parking_bay/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO