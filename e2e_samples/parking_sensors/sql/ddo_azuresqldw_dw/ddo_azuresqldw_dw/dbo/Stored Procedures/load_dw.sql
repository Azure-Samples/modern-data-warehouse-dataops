CREATE PROC [dbo].[load_dw] @load_id [VARCHAR](50) AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	-- DIM TABLES

    TRUNCATE TABLE dbo.[dim_parking_bay];
	INSERT INTO dbo.[dim_parking_bay]
	SELECT 
		CAST([dim_parking_bay_id] AS UNIQUEIDENTIFIER),
		[bay_id],
		[marker_id],
		[meter_id],
		[rd_seg_id],
		[rd_seg_dsc],
		[load_id],
		[loaded_on]
	FROM ext.[dim_parking_bay];

	--
	TRUNCATE TABLE dbo.[dim_location];
	INSERT INTO dbo.[dim_location]
	SELECT 
		CAST([dim_location_id] AS UNIQUEIDENTIFIER),
		[lat],
		[lon],
		[load_id],
		[loaded_on]
	FROM ext.[dim_location];

	--
	TRUNCATE TABLE dbo.[dim_st_marker];
	INSERT INTO dbo.[dim_st_marker]
	SELECT 
		CAST([dim_st_marker_id] AS UNIQUEIDENTIFIER),
		[st_marker_id],
		[load_id],
		[loaded_on]
	FROM ext.[dim_st_marker];


	-- FACT TABLES
	DELETE FROM dbo.[fact_parking] WHERE load_id=@load_id;
	INSERT INTO dbo.[fact_parking]
	SELECT 
		[dim_date_id],
		[dim_time_id],
		CAST([dim_parking_bay_id] AS UNIQUEIDENTIFIER),
		CAST([dim_location_id] AS UNIQUEIDENTIFIER),
		CAST([dim_st_marker_id] AS UNIQUEIDENTIFIER),
		[status],
		[load_id],
		[loaded_on]
	FROM ext.[fact_parking]
	WHERE load_id=@load_id;
END