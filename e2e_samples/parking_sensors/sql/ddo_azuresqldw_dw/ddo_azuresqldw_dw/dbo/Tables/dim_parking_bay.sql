CREATE TABLE [dbo].[dim_parking_bay] (
    [dim_parking_bay_id] UNIQUEIDENTIFIER NOT NULL,
    [bay_id]             INT              NULL,
    [marker_id]          NVARCHAR (50)    NULL,
    [meter_id]           NVARCHAR (50)    NULL,
    [rd_seg_id]          NVARCHAR (50)    NULL,
    [rd_seg_dsc]         NVARCHAR (500)   NULL,
    [load_id]            NVARCHAR (50)    NULL,
    [loaded_on]          DATETIME         NULL
)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE);



