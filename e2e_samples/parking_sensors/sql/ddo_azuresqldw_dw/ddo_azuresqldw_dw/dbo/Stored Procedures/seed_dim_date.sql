CREATE PROC [dbo].[seed_dim_date] AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	-- BASED ON: https://datasavvy.me/2016/08/06/create-a-date-dimension-in-azure-sql-data-warehouse/

	DECLARE @start_date DATE = '20100101', @number_of_years INT = 30;

	-- prevent set or regional settings from interfering with 
	-- interpretation of dates / literals

	CREATE TABLE #dimdate
	(
	  [date]       DATE,  
	  [day]        tinyint,
	  [month]      tinyint,
	  first_of_month date,
	  month_name  varchar(12),
	  [week]       tinyint,
	  ISO_week    tinyint,
	  day_of_week  tinyint,
	  [quarter]    tinyint,
	  [year]       smallint,
	  first_of_year  date,
	  style_112     char(8),
	  style_101     char(10)
	);


	SET DATEFIRST 7;
	SET DATEFORMAT mdy;
	SET LANGUAGE US_ENGLISH;

	DECLARE @cutoff_date DATE = DATEADD(YEAR, @number_of_years, @start_date);

	-- this is just a holding table for intermediate calculations:
	-- use the catalog views to generate as many rows as we need

	INSERT #dimdate([date]) 
	SELECT d
	FROM
	(
	  SELECT d = DATEADD(DAY, rn - 1, @start_date)
	  FROM 
	  (
		SELECT TOP (DATEDIFF(DAY, @start_date, @cutoff_date)) 
		  rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
		FROM sys.all_objects AS s1
		CROSS JOIN sys.all_objects AS s2
		ORDER BY s1.[object_id]
	  ) AS x
	) AS y;


	UPDATE #dimdate 
	set 
	  [day]        = DATEPART(DAY,      [date]),
	  [month]      = DATEPART(MONTH,    [date]),
	  first_of_month = CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
	  month_name  = DATENAME(MONTH,    [date]),
	  [week]       = DATEPART(WEEK,     [date]),
	  ISO_week    = DATEPART(ISO_WEEK, [date]),
	  day_of_week  = DATEPART(WEEKDAY,  [date]),
	  [quarter]    = DATEPART(QUARTER,  [date]),
	  [year]       = DATEPART(YEAR,     [date]),
	  first_of_year  = CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
	  style_112     = CONVERT(CHAR(8),   [date], 112),
	  style_101     = CONVERT(CHAR(10),  [date], 101)
	;


	INSERT INTO dbo.dim_date
	SELECT
	  dim_date_id       = CONVERT(INT, style_112),
	  [date]			= [date],
	  [day]				= CONVERT(TINYINT, [day]),
	  day_suffix		= CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
						CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
						WHEN '3' THEN 'rd' ELSE 'th' END END),
	  [week_day]		= CONVERT(TINYINT, day_of_week),
	  [week_day_name]	= CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
	  [DOW_in_month]	= CONVERT(TINYINT, ROW_NUMBER() OVER 
						(PARTITION BY first_of_month, day_of_week ORDER BY [date])),
	  [day_of_year]		= CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
	  week_of_month		= CONVERT(TINYINT, DENSE_RANK() OVER 
						(PARTITION BY [year], [month] ORDER BY [week])),
	  week_of_year		= CONVERT(TINYINT, [week]),
	  ISO_week_of_year	= CONVERT(TINYINT, [ISO_week]),
	  [month]			= CONVERT(TINYINT, [month]),
	  [month_name]		= CONVERT(VARCHAR(10), month_name),
	  [quarter]			= CONVERT(TINYINT, [quarter]),
	  quarter_name		= CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
						WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
	  [year]			= [year],
	  MMYYYY			= CONVERT(CHAR(6), LEFT(style_101, 2)    + LEFT(style_112, 4)),
	  month_year		= CONVERT(CHAR(8), LEFT(month_name, 3) + ' ' + LEFT(style_112, 4)),
	  first_day_of_month     = first_of_month,
	  last_day_of_month      = MAX([date]) OVER (PARTITION BY [year], [month]),
	  first_day_of_quarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
	  last_day_of_quarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
	  first_day_of_year      = first_of_year,
	  last_day_of_year       = MAX([date]) OVER (PARTITION BY [year]),
	  first_day_of_next_month = DATEADD(MONTH, 1, first_of_month),
	  first_day_of_next_year  = DATEADD(YEAR,  1, first_of_year)
	FROM #dimdate OPTION (MAXDOP 1);
	;

	-- NULL case
	-- NULL case
	INSERT INTO dbo.dim_date VALUES
	(-1
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL)
	DROP TABLE #dimdate
END