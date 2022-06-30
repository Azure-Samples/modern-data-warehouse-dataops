CREATE EXTERNAL TABLE [ext].[non_functional_bay] (
    [bay_id]             INT              NULL,
    [status]			 NVARCHAR (50)    NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/dw/non_functional_bay/',
    FILE_FORMAT = [ParquetFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );