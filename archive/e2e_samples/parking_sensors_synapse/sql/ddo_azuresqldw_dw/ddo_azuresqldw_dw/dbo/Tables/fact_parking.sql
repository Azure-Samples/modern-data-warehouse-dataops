CREATE TABLE [dbo].[fact_parking] (
    [dim_date_id]        NVARCHAR (50)    NULL,
    [dim_time_id]        NVARCHAR (50)    NULL,
    [dim_parking_bay_id] UNIQUEIDENTIFIER NULL,
    [dim_location_id]    UNIQUEIDENTIFIER NULL,
    [dim_st_marker_id]   UNIQUEIDENTIFIER NULL,
    [status]             NVARCHAR (50)    NULL,
    [load_id]            NVARCHAR (50)    NULL,
    [loaded_on]          DATETIME         NULL
)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH([dim_parking_bay_id]));

