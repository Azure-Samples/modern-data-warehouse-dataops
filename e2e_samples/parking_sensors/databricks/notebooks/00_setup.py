# Databricks notebook source
# MAGIC %md
# MAGIC ## Parameters

# COMMAND ----------

dbutils.widgets.text("catalogname", "", "Catalog Name")
catalogname = dbutils.widgets.get("catalogname")
dbutils.widgets.text("stgaccountname", "", "Storage Account Name")
stgaccountname = dbutils.widgets.get("stgaccountname")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup Catalog

# COMMAND ----------

spark.sql(f"USE CATALOG `{catalogname}`")

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

# fact_parking
spark.sql("DROP TABLE IF EXISTS dw.fact_parking;")
spark.sql(f"""
CREATE TABLE dw.fact_parking (
  dim_date_id STRING,
  dim_time_id STRING,
  dim_parking_bay_id STRING,
  dim_location_id STRING,
  dim_st_marker_id STRING,
  status STRING,
  load_id STRING,
  loaded_on TIMESTAMP
) USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/fact_parking/';
""")
spark.sql("REFRESH TABLE dw.fact_parking;")


# COMMAND ----------

# DIMENSION tables
# dim_st_marker
spark.sql("DROP TABLE IF EXISTS dw.dim_st_marker;")
spark.sql(f"""
CREATE TABLE dw.dim_st_marker (
  dim_st_marker_id STRING,
  st_marker_id STRING,
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/dim_st_marker/';
""")
spark.sql("REFRESH TABLE dw.dim_st_marker;")

# dim_location
spark.sql("DROP TABLE IF EXISTS dw.dim_location;")
spark.sql(f"""
CREATE TABLE dw.dim_location (
  dim_location_id STRING,
  lat FLOAT,
  lon FLOAT,
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/dim_location/';
""")
spark.sql("REFRESH TABLE dw.dim_location;")

# dim_parking_bay
spark.sql("DROP TABLE IF EXISTS dw.dim_parking_bay;")
spark.sql(f"""
CREATE TABLE dw.dim_parking_bay (
  dim_parking_bay_id STRING,
  bay_id INT,
  `marker_id` STRING, 
  `meter_id` STRING, 
  `rd_seg_dsc` STRING, 
  `rd_seg_id` STRING, 
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/dim_parking_bay/';
""")
spark.sql("REFRESH TABLE dw.dim_parking_bay;")

# COMMAND ----------

# MAGIC %sql 
# MAGIC DROP TABLE IF EXISTS dw.dim_date;
# MAGIC DROP TABLE IF EXISTS dw.dim_time;

# COMMAND ----------

from pyspark.sql.functions import col

# Define the ADLS Gen2 location
adls_gen2_location_seed = f"abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/seed/"
adls_gen2_location = f"abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/"

# DimDate
dbutils.fs.rm(f"{adls_gen2_location}dim_date", recurse=True)
dimdate = spark.read.csv(f"{adls_gen2_location_seed}dim_date/dim_date.csv", header=True)
dimdate.write.format("delta").option("path", f"{adls_gen2_location}dim_date").saveAsTable("dw.dim_date")

# DimTime
dbutils.fs.rm(f"{adls_gen2_location}dim_time", recurse=True)
dimtime = spark.read.csv(f"{adls_gen2_location_seed}dim_time/dim_time.csv", header=True)
dimtime.write.format("delta").option("path", f"{adls_gen2_location}dim_time").saveAsTable("dw.dim_time")

# COMMAND ----------

# INTERIM tables
# interim.parking_bay
spark.sql("DROP TABLE IF EXISTS interim.parking_bay;")
spark.sql(f"""
CREATE TABLE interim.parking_bay (
  bay_id INT,
  `last_edit` TIMESTAMP,
  `marker_id` STRING, 
  `meter_id` STRING, 
  `rd_seg_dsc` STRING, 
  `rd_seg_id` STRING, 
  `the_geom` STRUCT<`coordinates`: ARRAY<ARRAY<ARRAY<ARRAY<DOUBLE>>>>, `type`: STRING>,
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/interim/parking_bay/';
""")
spark.sql("REFRESH TABLE interim.parking_bay;")

# interim.sensor
spark.sql("DROP TABLE IF EXISTS interim.sensor;")
spark.sql(f"""
CREATE TABLE interim.sensor (
  bay_id INT,
  `st_marker_id` STRING,
  `lat` FLOAT,
  `lon` FLOAT, 
  `location` STRUCT<`coordinates`: ARRAY<DOUBLE>, `type`: STRING>, 
  `status` STRING, 
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/interim/sensors/';
""")
spark.sql("REFRESH TABLE interim.sensor;")

# COMMAND ----------

# ERROR tables
# malformed.parking_bay
spark.sql("DROP TABLE IF EXISTS malformed.parking_bay;")
spark.sql(f"""
CREATE TABLE malformed.parking_bay (
  bay_id INT,
  `last_edit` TIMESTAMP,
  `marker_id` STRING, 
  `meter_id` STRING, 
  `rd_seg_dsc` STRING, 
  `rd_seg_id` STRING, 
  `the_geom` STRUCT<`coordinates`: ARRAY<ARRAY<ARRAY<ARRAY<DOUBLE>>>>, `type`: STRING>,
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/malformed/parking_bay/';
""")
spark.sql("REFRESH TABLE malformed.parking_bay;")

# malformed.sensor
spark.sql("DROP TABLE IF EXISTS malformed.sensor;")
spark.sql(f"""
CREATE TABLE malformed.sensor (
  bay_id INT,
  `st_marker_id` STRING,
  `lat` FLOAT,
  `lon` FLOAT, 
  `location` STRUCT<`coordinates`: ARRAY<DOUBLE>, `type`: STRING>, 
  `status` STRING, 
  load_id STRING,
  loaded_on TIMESTAMP
)
USING parquet LOCATION 'abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/malformed/sensors/';
""")
spark.sql("REFRESH TABLE  malformed.sensor;")