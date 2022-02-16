CREATE TABLE [dbo].[dim_st_marker] (
    [dim_st_marker_id] UNIQUEIDENTIFIER NULL,
    [st_marker_id]     NVARCHAR (50)    NULL,
    [load_id]          NVARCHAR (50)    NULL,
    [loaded_on]        DATETIME         NULL
)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE);

