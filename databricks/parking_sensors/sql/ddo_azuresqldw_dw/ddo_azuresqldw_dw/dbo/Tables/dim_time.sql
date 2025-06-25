CREATE TABLE [dbo].[dim_time]
(
    [dim_time_id]               INT           NOT NULL,
    [time_alt_key]              INT           NOT NULL,
    [time]                      TIME (0)      NULL,
    [time_30]                   VARCHAR (8)   NOT NULL,
    [hour_30]                   TINYINT       NOT NULL,
    [minute_number]             TINYINT       NOT NULL,
    [second_number]             TINYINT       NOT NULL,
    [time_in_second]            INT           NOT NULL,
    [hourly_bucket]             VARCHAR (15)  NOT NULL,
    [day_time_bucket_group_key] INT           NOT NULL,
    [day_time_bucket]           VARCHAR (100) NOT NULL
)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE);
GO
