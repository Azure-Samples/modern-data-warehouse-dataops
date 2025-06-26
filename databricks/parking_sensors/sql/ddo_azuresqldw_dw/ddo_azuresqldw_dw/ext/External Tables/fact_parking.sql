CREATE EXTERNAL TABLE [ext].[fact_parking] (
    [dim_date_id] NVARCHAR (50) NULL,
    [dim_time_id] NVARCHAR (50) NULL,
    [dim_parking_bay_id] NVARCHAR (50) NULL,
    [dim_location_id] NVARCHAR (50) NULL,
    [dim_st_marker_id] NVARCHAR (50) NULL,
    [status] NVARCHAR (50) NULL,
    [load_id] NVARCHAR (50) NULL,
    [loaded_on] DATETIME NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/dw/fact_parking/',
    FILE_FORMAT = [ParquetFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );



