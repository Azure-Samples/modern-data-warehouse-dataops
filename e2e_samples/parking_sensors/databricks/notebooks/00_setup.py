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
# MAGIC ## Create Tables

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE SCHEMA IF NOT EXISTS dw;
# MAGIC CREATE SCHEMA IF NOT EXISTS lnd;
# MAGIC CREATE SCHEMA IF NOT EXISTS interim;
# MAGIC CREATE SCHEMA IF NOT EXISTS malformed;

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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/dw/fact_parking/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/dw/dim_st_marker/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/dw/dim_location/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/dw/dim_parking_bay/';
# MAGIC 
# MAGIC REFRESH TABLE dw.dim_parking_bay;

# COMMAND ----------

# MAGIC %sql 
# MAGIC DROP TABLE IF EXISTS dw.dim_date;
# MAGIC DROP TABLE IF EXISTS dw.dim_time;

# COMMAND ----------

from pyspark.sql.functions import col

# DimDate
dimdate = spark.read.csv("dbfs:/mnt/datalake/data/seed/dim_date/dim_date.csv", header=True)
dimdate.write.saveAsTable("dw.dim_date")

# DimTime
dimtime = spark.read.csv("dbfs:/mnt/datalake/data/seed/dim_time/dim_time.csv", header=True)
dimtime.write.saveAsTable("dw.dim_time")

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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/interim/parking_bay/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/interim/sensors/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/interim/parking_bay/';
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
# MAGIC )
# MAGIC USING parquet
# MAGIC LOCATION '/mnt/datalake/data/interim/sensors/';
# MAGIC 
# MAGIC REFRESH TABLE interim.sensor;

# COMMAND ----------


