# Databricks notebook source

# MAGIC %md
# MAGIC ## Mount ADLS Gen2

# COMMAND ----------

import os

# Set mount path
storage_mount_data_path = os.environ['MOUNT_DATA_PATH']
storage_mount_container = os.environ['MOUNT_DATA_CONTAINER']

# Unmount if existing
for mp in dbutils.fs.mounts():
  if mp.mountPoint == storage_mount_data_path:
    dbutils.fs.unmount(storage_mount_data_path)

# Refresh mounts
dbutils.fs.refreshMounts()

# COMMAND ----------

# Retrieve storage credentials
storage_account = dbutils.secrets.get(scope = "storage_scope", key = "datalakeAccountName")
storage_sp_id = dbutils.secrets.get(scope = "storage_scope", key = "spStorId")
storage_sp_key = dbutils.secrets.get(scope = "storage_scope", key = "spStorPass")
storage_sp_tenant = dbutils.secrets.get(scope = "storage_scope", key = "spStorTenantId")

# Mount
configs = {"fs.azure.account.auth.type": "OAuth",
           "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
           "fs.azure.account.oauth2.client.id": storage_sp_id,
           "fs.azure.account.oauth2.client.secret": storage_sp_key,
           "fs.azure.account.oauth2.client.endpoint": "https://login.microsoftonline.com/" + storage_sp_tenant + "/oauth2/token"} 


# Optionally, you can add <your-directory-name> to the source URI of your mount point.
dbutils.fs.mount(
  source = "abfss://" + storage_mount_container + "@" + storage_account + ".dfs.core.windows.net/",
  mount_point = storage_mount_data_path,
  extra_configs = configs)


# Refresh mounts
dbutils.fs.refreshMounts()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Use the Sensor Catalog Created in the Prerequisites 

# COMMAND ----------
# MAGIC %sql
# MAGIC USE Catalog sensordata
# COMMAND ----------

# MAGIC %md
# MAGIC ## Create Schemas

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE SCHEMA IF NOT EXISTS dw;
# MAGIC CREATE SCHEMA IF NOT EXISTS lnd;
# MAGIC CREATE SCHEMA IF NOT EXISTS interim;
# MAGIC CREATE SCHEMA IF NOT EXISTS malformed;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create Tables

# COMMAND ----------


# MAGIC %sql
# MAGIC -- FACT tables
# MAGIC DROP TABLE IF EXISTS dw.fact_parking;
# MAGIC CREATE TABLE dw.fact_parking (
# MAGIC   dim_date_id STRING,
# MAGIC   dim_time_id STRING,
# MAGIC   dim_parking_bay_id STRING,
# MAGIC   dim_location_id STRING,
# MAGIC   dim_st_marker_id STRING,
# MAGIC   status STRING,
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE dw.fact_parking;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- DIMENSION tables
# MAGIC DROP TABLE IF EXISTS dw.dim_st_marker;
# MAGIC CREATE TABLE dw.dim_st_marker (
# MAGIC   dim_st_marker_id STRING,
# MAGIC   st_marker_id STRING,
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE dw.dim_st_marker;
# MAGIC 
# MAGIC --
# MAGIC DROP TABLE IF EXISTS dw.dim_location;
# MAGIC CREATE TABLE dw.dim_location (
# MAGIC   dim_location_id STRING,
# MAGIC   lat FLOAT,
# MAGIC   lon FLOAT,
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE dw.dim_location;
# MAGIC 
# MAGIC --
# MAGIC DROP TABLE IF EXISTS dw.dim_parking_bay;
# MAGIC CREATE TABLE dw.dim_parking_bay (
# MAGIC   dim_parking_bay_id STRING,
# MAGIC   bay_id INT,
# MAGIC   `marker_id` STRING, 
# MAGIC   `meter_id` STRING, 
# MAGIC   `rd_seg_dsc` STRING, 
# MAGIC   `rd_seg_id` STRING, 
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE dw.dim_parking_bay;

# COMMAND ----------

# MAGIC %sql 
# MAGIC DROP TABLE IF EXISTS dw.dim_date;
# MAGIC DROP TABLE IF EXISTS dw.dim_time;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create and load generated Date Dim

# COMMAND ----------


# MAGIC %sql
# MAGIC -- Create the Date Dimension table
# MAGIC CREATE TABLE dw.dim_date (
# MAGIC dim_date_id INT,
# MAGIC     date TIMESTAMP,
# MAGIC     day INT,
# MAGIC     day_suffix STRING,
# MAGIC     week_day INT,
# MAGIC     week_day_name STRING,
# MAGIC     DOW_in_month INT,
# MAGIC     day_of_year INT,
# MAGIC     week_of_month INT,
# MAGIC     week_of_year INT,
# MAGIC     ISO_week_of_year INT,
# MAGIC     month INT,
# MAGIC     month_name STRING,
# MAGIC     quarter INT,
# MAGIC     quarter_name STRING,
# MAGIC     year INT,
# MAGIC     MMYYYY STRING,
# MAGIC     month_year STRING,
# MAGIC     first_day_of_month TIMESTAMP,
# MAGIC     last_day_of_month TIMESTAMP,
# MAGIC     first_day_of_quarter TIMESTAMP,
# MAGIC     last_day_of_quarter TIMESTAMP,
# MAGIC     first_day_of_year TIMESTAMP,
# MAGIC     last_day_of_year TIMESTAMP,
# MAGIC     first_day_of_next_month TIMESTAMP,
# MAGIC     first_day_of_next_year TIMESTAMP
# MAGIC );

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Insert data for dates from 2010 to 2030
# MAGIC WITH date_series AS (
# MAGIC     -- Generate a sequence of dates from 1st January 2010 to 31st December 2030
# MAGIC     -- Date Ranges can be adjusted in the code
# MAGIC     SELECT explode(sequence(to_date('2010-01-01'), to_date('2030-12-31'), interval 1 day)) AS date
# MAGIC )
# MAGIC INSERT INTO dw.dim_date (
# MAGIC     dim_date_id, date, day, day_suffix, week_day, week_day_name, DOW_in_month, day_of_year, 
# MAGIC     week_of_month, week_of_year, ISO_week_of_year, month, month_name, quarter, quarter_name,
# MAGIC     year, MMYYYY, month_year, first_day_of_month, last_day_of_month, first_day_of_quarter, 
# MAGIC     last_day_of_quarter, first_day_of_year, last_day_of_year, first_day_of_next_month, 
# MAGIC     first_day_of_next_year
# MAGIC )
# MAGIC SELECT 
# MAGIC     -- dim_date_id (row number based on date)
# MAGIC     CAST(DATE_FORMAT(date, 'yyyyMMdd') AS INT) AS dim_date_id,
# MAGIC     date,
# MAGIC     DAY(date) AS day,
# MAGIC     CASE 
# MAGIC         WHEN DAY(date) IN (1, 21, 31) THEN 'st'
# MAGIC         WHEN DAY(date) IN (2, 22) THEN 'nd'
# MAGIC         WHEN DAY(date) IN (3, 23) THEN 'rd'
# MAGIC         ELSE 'th'
# MAGIC     END AS day_suffix,
# MAGIC     DAYOFWEEK(date) AS week_day,
# MAGIC     DATE_FORMAT(date, 'EEEE') AS week_day_name,
# MAGIC     DAY(date) - (DAY(date) - 1) % 7 AS DOW_in_month,
# MAGIC     DAYOFYEAR(date) AS day_of_year,
# MAGIC     CAST( (DAY(date) - 1) / 7 + 1 AS INT) AS week_of_month,
# MAGIC     WEEKOFYEAR(date) AS week_of_year,
# MAGIC     WEEKOFYEAR(date) AS ISO_week_of_year,
# MAGIC     MONTH(date) AS month,  -- This is correct for extracting the month
# MAGIC     ---MONTHNAME(date) AS month_name,  -- Correct Spark SQL function for full month name after Spark version 15.1
# MAGIC    DATE_FORMAT(date, 'MMMM') AS month_name,  -- Correct Spark SQL function for full month name pre-Spark version 15.1
# MAGIC     QUARTER(date) AS quarter,  -- Extract quarter of the year
# MAGIC     CASE 
# MAGIC         WHEN QUARTER(date) = 1 THEN 'First'
# MAGIC         WHEN QUARTER(date) = 2 THEN 'Second'
# MAGIC         WHEN QUARTER(date) = 3 THEN 'Third'
# MAGIC         ELSE 'Fourth'
# MAGIC     END AS quarter_name,
# MAGIC     YEAR(date) AS year,  -- Extract year
# MAGIC     DATE_FORMAT(date, 'MMyyyy') AS MMYYYY,  -- Format to 'MMYYYY'
# MAGIC     DATE_FORMAT(date, 'MM-yyyy') AS month_year,  -- Format to 'yyyy-MM'
# MAGIC         -- First day of the month
# MAGIC     DATE_FORMAT(date, 'yyyy-MM-01') AS first_day_of_month,
# MAGIC      -- Last day of the month
# MAGIC     LAST_DAY(date) AS last_day_of_month,
# MAGIC -- First day of the quarter
# MAGIC   CASE
# MAGIC         WHEN QUARTER(date) = 1 THEN DATE_FORMAT(date, 'yyyy-01-01') 
# MAGIC         WHEN QUARTER(date) = 2 THEN DATE_FORMAT(date, 'yyyy-04-01') 
# MAGIC         WHEN QUARTER(date) = 3 THEN DATE_FORMAT(date, 'yyyy-07-01') 
# MAGIC         ELSE DATE_FORMAT(date, 'yyyy-10-01') 
# MAGIC         END AS first_day_of_quarter,
# MAGIC   -- Last day of the quarter
# MAGIC   CASE 
# MAGIC         WHEN QUARTER(date) = 1 THEN DATE_FORMAT(date, 'yyyy-03-31') 
# MAGIC         WHEN QUARTER(date) = 2 THEN DATE_FORMAT(date, 'yyyy-06-30') 
# MAGIC         WHEN QUARTER(date) = 3 THEN DATE_FORMAT(date, 'yyyy-09-30') 
# MAGIC         ELSE DATE_FORMAT(date, 'yyyy-12-31') 
# MAGIC         END AS last_day_of_quarter,
# MAGIC     -- First day of the year
# MAGIC     DATE_FORMAT(date, 'yyyy-01-01') AS first_day_of_year,
# MAGIC     -- Last day of the year
# MAGIC     DATE_FORMAT(date, 'yyyy-12-31') AS last_day_of_year,
# MAGIC     -- First day of the next month
# MAGIC     DATE_FORMAT(DATE_ADD(LAST_DAY(date), CAST(1 AS INT)), 'yyyy-MM-01') AS first_day_of_next_month,
# MAGIC     -- First day of the next year
# MAGIC     DATE_ADD(DATE_FORMAT(date, 'yyyy-12-31'), 1)  AS first_day_of_next_year
# MAGIC FROM date_series;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create and load generated Time Dim

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Create the Time Dimension table
# MAGIC CREATE TABLE dw.dim_time (
# MAGIC     dim_time_id INT,
# MAGIC     time_alt_key INT,
# MAGIC     time STRING,
# MAGIC     time_30 STRING,
# MAGIC     hour_30 INT,
# MAGIC     minute_number INT,
# MAGIC     second_number INT,
# MAGIC     time_in_second INT,
# MAGIC     hourly_bucket STRING,
# MAGIC     day_time_bucket_group_key INT,
# MAGIC     day_time_bucket STRING
# MAGIC );

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Insert a dummy row into the dim_time table
# MAGIC INSERT INTO dw.dim_time (
# MAGIC     dim_time_id, time_alt_key, time, time_30, hour_30, minute_number, second_number, 
# MAGIC     time_in_second, hourly_bucket, day_time_bucket_group_key, day_time_bucket
# MAGIC )
# MAGIC VALUES (
# MAGIC     -1,          -- dim_time_id
# MAGIC     -1,          -- time_alt_key
# MAGIC     '0:00:00',   -- time (dummy value, can be adjusted)
# MAGIC     '0:00:00',   -- time_30 (dummy value, can be adjusted)
# MAGIC     0,           -- hour_30 (dummy value)
# MAGIC     0,           -- minute_number (dummy value)
# MAGIC     -1,          -- second_number (dummy value)
# MAGIC     -1,          -- time_in_second (dummy value)
# MAGIC     NULL,        -- hourly_bucket (dummy value, no valid bucket for the row)
# MAGIC     NULL,        -- day_time_bucket_group_key (dummy value, no valid grouping)
# MAGIC     NULL         -- day_time_bucket (dummy value, no valid bucket description)
# MAGIC );

# COMMAND ----------

# MAGIC %sql
# MAGIC --Generate Data for 24 hour interval
# MAGIC WITH time_series AS (
# MAGIC     SELECT explode(sequence(
# MAGIC         to_timestamp('2023-01-01 00:00:00'),  -- Start of the day
# MAGIC         to_timestamp('2023-01-01 23:59:59'),  -- End of the day
# MAGIC         interval 1 second                      -- Step size of 1 second
# MAGIC     )) AS time
# MAGIC )
# MAGIC INSERT INTO dw.dim_time (
# MAGIC    dim_time_id, time_alt_key, time, time_30, hour_30, minute_number, second_number, 
# MAGIC     time_in_second, hourly_bucket, day_time_bucket_group_key, day_time_bucket
# MAGIC )
# MAGIC SELECT 
# MAGIC 
# MAGIC     ROW_NUMBER() OVER (ORDER BY time) - 1 AS dim_time_id,
# MAGIC     CAST(DATE_FORMAT(time, 'HHmmss') AS INT) AS time_alt_key,
# MAGIC     DATE_FORMAT(time, 'HH:mm:ss') AS time,
# MAGIC     DATE_FORMAT(time, 'HH:mm:ss') AS time_30,  -- Adjust for rounded time if needed
# MAGIC     HOUR(time) AS hour_30,
# MAGIC     MINUTE(time) AS minute_number,
# MAGIC     SECOND(time) AS second_number,
# MAGIC     CAST(UNIX_TIMESTAMP(time) - UNIX_TIMESTAMP('2023-01-01 00:00:00') AS INT) AS time_in_second,
# MAGIC     CONCAT(LPAD(HOUR(time), 2, '0'), ':00-', LPAD(HOUR(time), 2, '0'), ':59') AS hourly_bucket,
# MAGIC     CASE 
# MAGIC         WHEN HOUR(time) BETWEEN 0 AND 2 THEN 0  -- Late Night (00:00 AM To 02:59 AM)
# MAGIC         WHEN HOUR(time) BETWEEN 3 AND 6 THEN 1  -- Early Morning (03:00 AM To 06:59 AM)
# MAGIC         WHEN HOUR(time) BETWEEN 7 AND 8 THEN 2  -- AM Peak (07:00 AM To 08:59 AM)
# MAGIC         WHEN HOUR(time) BETWEEN 9 AND 11 THEN 3 -- Mid Morning (09:00 AM To 11:59 AM)
# MAGIC         WHEN HOUR(time) BETWEEN 12 AND 13 THEN 4 -- Lunch (12:00 PM To 13:59 PM)
# MAGIC         WHEN HOUR(time) BETWEEN 14 AND 15 THEN 5 -- Mid Afternoon (14:00 PM To 15:59 PM)
# MAGIC         WHEN HOUR(time) BETWEEN 16 AND 17 THEN 6 -- PM Peak (16:00 PM To 17:59 PM)
# MAGIC         WHEN HOUR(time) BETWEEN 18 AND 23 THEN 7 -- Evening (18:00 PM To 23:59 PM)
# MAGIC     END AS day_time_bucket_group_key,
# MAGIC     CASE 
# MAGIC         WHEN HOUR(time) BETWEEN 0 AND 2 THEN 'Late Night (00:00 AM To 02:59 AM)'
# MAGIC         WHEN HOUR(time) BETWEEN 3 AND 6 THEN 'Early Morning (03:00 AM To 06:59 AM)'
# MAGIC         WHEN HOUR(time) BETWEEN 7 AND 8 THEN 'AM Peak (07:00 AM To 08:59 AM)'
# MAGIC         WHEN HOUR(time) BETWEEN 9 AND 11 THEN 'Mid Morning (09:00 AM To 11:59 AM)'
# MAGIC         WHEN HOUR(time) BETWEEN 12 AND 13 THEN 'Lunch (12:00 PM To 13:59 PM)'
# MAGIC         WHEN HOUR(time) BETWEEN 14 AND 15 THEN 'Mid Afternoon (14:00 PM To 15:59 PM)'
# MAGIC         WHEN HOUR(time) BETWEEN 16 AND 17 THEN 'PM Peak (16:00 PM To 17:59 PM)'
# MAGIC         WHEN HOUR(time) BETWEEN 18 AND 23 THEN 'Evening (18:00 PM To 23:59 PM)'
# MAGIC     END AS day_time_bucket
# MAGIC FROM time_series;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- INTERIM tables
# MAGIC DROP TABLE IF EXISTS interim.parking_bay;
# MAGIC CREATE TABLE interim.parking_bay (
# MAGIC   bay_id INT,
# MAGIC   `last_edit` TIMESTAMP,
# MAGIC   `marker_id` STRING, 
# MAGIC   `meter_id` STRING, 
# MAGIC   `rd_seg_dsc` STRING, 
# MAGIC   `rd_seg_id` STRING, 
# MAGIC   `the_geom` STRUCT<`coordinates`: ARRAY<ARRAY<ARRAY<ARRAY<DOUBLE>>>>, `type`: STRING>,
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE interim.parking_bay;
# MAGIC 
# MAGIC --
# MAGIC DROP TABLE IF EXISTS interim.sensor;
# MAGIC CREATE TABLE interim.sensor (
# MAGIC   bay_id INT,
# MAGIC   `st_marker_id` STRING,
# MAGIC   `lat` FLOAT,
# MAGIC   `lon` FLOAT, 
# MAGIC   `location` STRUCT<`coordinates`: ARRAY<DOUBLE>, `type`: STRING>, 
# MAGIC   `status` STRING, 
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE interim.sensor;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- ERROR tables
# MAGIC DROP TABLE IF EXISTS malformed.parking_bay;
# MAGIC CREATE TABLE malformed.parking_bay (
# MAGIC   bay_id INT,
# MAGIC   `last_edit` TIMESTAMP,
# MAGIC   `marker_id` STRING, 
# MAGIC   `meter_id` STRING, 
# MAGIC   `rd_seg_dsc` STRING, 
# MAGIC   `rd_seg_id` STRING, 
# MAGIC   `the_geom` STRUCT<`coordinates`: ARRAY<ARRAY<ARRAY<ARRAY<DOUBLE>>>>, `type`: STRING>,
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE interim.parking_bay;
# MAGIC 
# MAGIC --
# MAGIC DROP TABLE IF EXISTS malformed.sensor;
# MAGIC CREATE TABLE malformed.sensor (
# MAGIC   bay_id INT,
# MAGIC   `st_marker_id` STRING,
# MAGIC   `lat` FLOAT,
# MAGIC   `lon` FLOAT, 
# MAGIC   `location` STRUCT<`coordinates`: ARRAY<DOUBLE>, `type`: STRING>, 
# MAGIC   `status` STRING, 
# MAGIC   load_id STRING,
# MAGIC   loaded_on TIMESTAMP
# MAGIC );
# MAGIC 
# MAGIC REFRESH TABLE interim.sensor;

# COMMAND ----------


