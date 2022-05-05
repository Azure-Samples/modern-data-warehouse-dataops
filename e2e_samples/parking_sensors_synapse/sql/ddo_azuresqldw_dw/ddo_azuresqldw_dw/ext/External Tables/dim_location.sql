CREATE EXTERNAL TABLE [ext].[dim_location] (
    [dim_location_id] NVARCHAR (50) NULL,
    [lat] REAL NULL,
    [lon] REAL NULL,
    [load_id] NVARCHAR (50) NULL,
    [loaded_on] DATETIME NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/dw/dim_location/',
    FILE_FORMAT = [ParquetFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );



