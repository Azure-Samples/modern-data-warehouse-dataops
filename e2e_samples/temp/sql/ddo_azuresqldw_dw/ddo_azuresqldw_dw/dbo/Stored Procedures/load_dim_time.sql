CREATE PROC [dbo].[load_dim_time] AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    TRUNCATE TABLE dbo.[dim_time];
	INSERT INTO dbo.[dim_time]
	SELECT 
		[dim_time_id]
      ,[time_alt_key]
      ,CAST([time_30] AS time)
      ,[time_30]
      ,[hour_30]
      ,[minute_number]
      ,[second_number]
      ,[time_in_second]
      ,[hourly_bucket]
      ,[day_time_bucket_group_key]
      ,[day_time_bucket]
	FROM ext.[dim_time];

END