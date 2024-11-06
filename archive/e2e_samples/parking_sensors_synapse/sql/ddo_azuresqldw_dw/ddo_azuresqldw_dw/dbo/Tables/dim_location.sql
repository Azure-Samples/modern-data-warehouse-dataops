CREATE TABLE [dbo].[dim_location] (
    [dim_location_id] UNIQUEIDENTIFIER NOT NULL,
    [lat]             REAL             NULL,
    [lon]             REAL             NULL,
    [load_id]         NVARCHAR (50)    NULL,
    [loaded_on]       DATETIME         NULL
)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE);



