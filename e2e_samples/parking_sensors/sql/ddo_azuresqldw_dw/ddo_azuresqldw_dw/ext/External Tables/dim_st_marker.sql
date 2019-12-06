CREATE EXTERNAL TABLE [ext].[dim_st_marker] (
    [dim_st_marker_id] NVARCHAR (50) NULL,
    [st_marker_id] NVARCHAR (50) NULL,
    [load_id] NVARCHAR (50) NULL,
    [loaded_on] DATETIME NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/dw/dim_st_marker/',
    FILE_FORMAT = [ParquetFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );



