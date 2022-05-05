CREATE EXTERNAL TABLE [ext].[dim_date] (
    [dim_date_id] INT NULL,
    [date] VARCHAR (27) NULL,
    [day] TINYINT NULL,
    [day_suffix] CHAR (2) NULL,
    [week_day] TINYINT NULL,
    [week_day_name] VARCHAR (10) NULL,
    [DOW_in_month] TINYINT NULL,
    [day_of_year] SMALLINT NULL,
    [week_of_month] TINYINT NULL,
    [week_of_year] TINYINT NULL,
    [ISO_week_of_year] TINYINT NULL,
    [month] TINYINT NULL,
    [month_name] VARCHAR (10) NULL,
    [quarter] TINYINT NULL,
    [quarter_name] VARCHAR (6) NULL,
    [year] SMALLINT NULL,
    [MMYYYY] CHAR (6) NULL,
    [month_year] CHAR (8) NULL,
    [first_day_of_month] VARCHAR (27) NULL,
    [last_day_of_month] VARCHAR (27) NULL,
    [first_day_of_quarter] VARCHAR (27) NULL,
    [last_day_of_quarter] VARCHAR (27) NULL,
    [first_day_of_year] VARCHAR (27) NULL,
    [last_day_of_year] VARCHAR (27) NULL,
    [first_day_of_next_month] VARCHAR (27) NULL,
    [first_day_of_next_year] VARCHAR (27) NULL
)
    WITH (
    DATA_SOURCE = [AzureDataLakeStorage],
    LOCATION = N'data/seed/dim_date/',
    FILE_FORMAT = [CSVSkipHeaderFileFormat],
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
    );

