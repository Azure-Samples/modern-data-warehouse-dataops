CREATE PROC [dbo].[load_dim_date] AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    TRUNCATE TABLE dbo.[dim_date];
	INSERT INTO dbo.[dim_date]
	SELECT 
		[dim_date_id],
		CAST([date] AS DATE),
		[day],
		[day_suffix],
		[week_day],
		[week_day_name],
		[DOW_in_month],
		[day_of_year],
		[week_of_month],
		[week_of_year],
		[ISO_week_of_year],
		[month] [tinyint],
		[month_name],
		[quarter],
		[quarter_name],
		[year],
		[MMYYYY],
		[month_year],
		CAST([first_day_of_month] AS DATE),
		CAST([last_day_of_month] AS DATE),
		CAST([first_day_of_quarter] AS DATE),
		CAST([last_day_of_quarter] AS DATE),
		CAST([first_day_of_year] AS DATE),
		CAST([last_day_of_year] AS DATE),
		CAST([first_day_of_next_month] AS DATE),
		CAST([first_day_of_next_year] AS DATE)
	FROM ext.[dim_date];

END