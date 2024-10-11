CREATE EXTERNAL TABLE [ext].[dim_parking_bay] (
    [dim_parking_bay_id] NVARCHAR (50) NULL,
    [bay_id] INT NULL,
    [marker_id] NVARCHAR (50) NULL,
    [meter_id] NVARCHAR (50) NULL,
    [rd_seg_dsc] NVARCHAR (MAX) NULL,
    [rd_seg_id] NVARCHAR (50) NULL,
    [load_id] NVARCHAR (50) NULL,
    [loaded_on] DATETIME NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/dw/dim_parking_bay/',
    FILE_FORMAT = [ParquetFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );



