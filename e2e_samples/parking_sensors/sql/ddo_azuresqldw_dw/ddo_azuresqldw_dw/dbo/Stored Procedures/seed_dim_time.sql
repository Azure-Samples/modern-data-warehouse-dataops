
-- =============================================
-- Author:      Lace Lofranco
-- Create Date: 2018-05-16
-- Description: Seeds the dim_time table. DOES NOT delete existing data
-- =============================================

CREATE PROCEDURE [dbo].[seed_dim_time]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	CREATE TABLE #dim_time (
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
	--Specify Total Number of Hours You need to fill in Time Dimension 
	DECLARE @Size INTEGER 
	--iF @Size=32 THEN This will Fill values Upto 32:59 hr in Time Dimension 
	Set @Size=23 
	DECLARE @hour INTEGER 
	DECLARE @minute INTEGER 
	DECLARE @second INTEGER 
	DECLARE @k INTEGER 
	DECLARE @time_at_key INTEGER 
	DECLARE @time_in_seconds INTEGER 
	DECLARE @time_30 varchar(25) 
	DECLARE @time TIME(0) = '00:00:00'
	DECLARE @hour_30 varchar(4) 
	DECLARE @minute_30 varchar(4) 
	DECLARE @second_30 varchar(4) 
	DECLARE @hour_bucket varchar(15) 
	DECLARE @hour_bucket_group_key int 
	DECLARE @day_time_bucket varchar(100) 
	DECLARE @day_time_bucket_group_key int 
	SET @hour = 0 
	SET @minute = 0 
	SET @second = 0 
	SET @k = 0 
	SET @time_at_key = 0 

	WHILE(@hour<= @Size ) 
	BEGIN 
		IF (@hour <10 ) 
		BEGIN
		SET @hour_30 = '0' + cast( @hour as varchar(10)) 
		END 
		ELSE 
		BEGIN 
		SET @hour_30 = @hour 
		END 
		--Create Hour Bucket Value 
		SET @hour_bucket= @hour_30+':00' +'-' +@hour_30+':59' 
		WHILE(@minute <= 59) 
		BEGIN 
			WHILE(@second <= 59) 
			BEGIN 
				SET @time_at_key = @hour *10000 +@minute*100 +@second 
				SET @time_in_seconds =@hour * 3600 + @minute *60 +@second 
				IF @minute <10 
				BEGIN 
				SET @minute_30 = '0' + cast ( @minute as varchar(10) ) 
				END 
				ELSE 
				BEGIN 
				SET @minute_30 = @minute 
				END 
				IF @second <10 
				BEGIN 
				SET @second_30 = '0' + cast ( @second as varchar(10) ) 
				END 
				ELSE 
				BEGIN 
				SET @second_30 = @second 
				END 
				--Concatenate values for Time30 
				SET @time_30 = @hour_30 +':'+@minute_30 +':'+@second_30 
				--DayTimeBucketGroupKey can be used in Sorting of DayTime Bucket In proper Order 
				SELECT @day_time_bucket_group_key = 
				CASE 
				WHEN (@time_at_key >= 00000 AND @time_at_key <= 25959) THEN 0 
				WHEN (@time_at_key >= 30000 AND @time_at_key <= 65959) THEN 1 
				WHEN (@time_at_key >= 70000 AND @time_at_key <= 85959) THEN 2 
				WHEN (@time_at_key >= 90000 AND @time_at_key <= 115959) THEN 3 
				WHEN (@time_at_key >= 120000 AND @time_at_key <= 135959)THEN 4 
				WHEN (@time_at_key >= 140000 AND @time_at_key <= 155959)THEN 5 
				WHEN (@time_at_key >= 50000 AND @time_at_key <= 175959) THEN 6 
				WHEN (@time_at_key >= 180000 AND @time_at_key <= 235959)THEN 7 
				WHEN (@time_at_key >= 240000) THEN 8 
				END 
				--print @day_time_bucket_group_key 
				-- DayTimeBucket Time Divided in Specific Time Zone 
				-- So Data can Be Grouped as per Bucket for Analyzing as per time of day 
				SELECT @day_time_bucket = 
				CASE 
					WHEN (@time_at_key >= 00000 AND @time_at_key <= 25959) 
					THEN 'Late Night (00:00 AM To 02:59 AM)' 
					WHEN (@time_at_key >= 30000 AND @time_at_key <= 65959) 
					THEN 'Early Morning(03:00 AM To 6:59 AM)' 
					WHEN (@time_at_key >= 70000 AND @time_at_key <= 85959) 
					THEN 'AM Peak (7:00 AM To 8:59 AM)' 
					WHEN (@time_at_key >= 90000 AND @time_at_key <= 115959) 
					THEN 'Mid Morning (9:00 AM To 11:59 AM)' 
					WHEN (@time_at_key >= 120000 AND @time_at_key <= 135959) 
					THEN 'Lunch (12:00 PM To 13:59 PM)' 
					WHEN (@time_at_key >= 140000 AND @time_at_key <= 155959)
					THEN 'Mid Afternoon (14:00 PM To 15:59 PM)' 
					WHEN (@time_at_key >= 50000 AND @time_at_key <= 175959)
					THEN 'PM Peak (16:00 PM To 17:59 PM)' 
					WHEN (@time_at_key >= 180000 AND @time_at_key <= 235959)
					THEN 'Evening (18:00 PM To 23:59 PM)' 
					WHEN (@time_at_key >= 240000) THEN 'Previous Day Late Night (24:00 PM to '+cast( @Size as varchar(10)) +':00 PM )' 
				END 
				-- print @day_time_bucket 
				INSERT into #dim_time
				(
					dim_time_id, time_alt_key, [time], [time_30], [hour_30],
					[minute_number], [second_number], [time_in_second], [hourly_bucket],
					day_time_bucket_group_key, day_time_bucket
				) 
				VALUES
				(
					@k,@time_at_key, @time, @time_30, @hour, @minute, @Second, 
					@time_in_seconds, @hour_bucket, @day_time_bucket_group_key, @day_time_bucket
				) 
				SET @second = @second + 1 
				SET @k = @k + 1 
			END 
			SET @minute = @minute + 1 
			SET @second = 0 
		END 
		SET @hour = @hour + 1 
		SET @minute =0 
	END;

	UPDATE #dim_time
	SET [time] = CAST(time_30 AS TIME(0))

	INSERT INTO dbo.dim_time SELECT * FROM #dim_time

	-- NULL case
	INSERT INTO dbo.dim_time VALUES
	(-1, 
	-1,
	NULL,
	'',
	0,
	0,
	0,
	-1,
	'',
	-1,
	''
	)

END