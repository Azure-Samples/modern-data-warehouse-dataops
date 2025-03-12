# Databricks notebook source
# MAGIC %pip install opencensus-ext-azure==1.1.14

# COMMAND ----------

dbutils.widgets.text("loadid", "", "Load Id")
loadid = dbutils.widgets.get("loadid")

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

import datetime
import os
from pyspark.sql.functions import col, lit
import ddo_transform.transform as t
import ddo_transform.util as util

load_id = loadid
loaded_on = datetime.datetime.now()
loaded_on = datetime.datetime.now()
base_path = f"abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/dw/"

# Read interim cleansed data
parkingbay_sdf = spark.read.table(f"`{catalogname}`.interim.parking_bay").filter(col('load_id') == lit(load_id))
sensordata_sdf = spark.read.table(f"`{catalogname}`.interim.sensor").filter(col('load_id') == lit(load_id))

# COMMAND ----------

# MAGIC %md
# MAGIC ### Transform and load Dimension tables

# COMMAND ----------

# Read existing Dimensions
dim_parkingbay_sdf = spark.read.table(f"`{catalogname}`.dw.dim_parking_bay")
dim_location_sdf = spark.read.table(f"`{catalogname}`.dw.dim_location")
dim_st_marker = spark.read.table(f"`{catalogname}`.dw.dim_st_marker")

# Transform
new_dim_parkingbay_sdf = t.process_dim_parking_bay(parkingbay_sdf, dim_parkingbay_sdf, load_id, loaded_on).cache()
new_dim_location_sdf = t.process_dim_location(sensordata_sdf, dim_location_sdf, load_id, loaded_on).cache()
new_dim_st_marker_sdf = t.process_dim_st_marker(sensordata_sdf, dim_st_marker, load_id, loaded_on).cache()

# Load
util.save_overwrite_unmanaged_table(spark, new_dim_parkingbay_sdf, table_name=f"`{catalogname}`.dw.dim_parking_bay", path=os.path.join(base_path, "dim_parking_bay"))
util.save_overwrite_unmanaged_table(spark, new_dim_location_sdf, table_name=f"`{catalogname}`.dw.dim_location", path=os.path.join(base_path, "dim_location"))
util.save_overwrite_unmanaged_table(spark, new_dim_st_marker_sdf, table_name=f"`{catalogname}`.dw.dim_st_marker", path=os.path.join(base_path, "dim_st_marker"))

# COMMAND ----------

# MAGIC %md
# MAGIC ### Transform and load Fact tables

# COMMAND ----------

# Read existing Dimensions
dim_parkingbay_sdf = spark.read.table(f"`{catalogname}`.dw.dim_parking_bay")
dim_location_sdf = spark.read.table(f"`{catalogname}`.dw.dim_location")
dim_st_marker = spark.read.table(f"`{catalogname}`.dw.dim_st_marker")

# Process
nr_fact_parking = t.process_fact_parking(sensordata_sdf, dim_parkingbay_sdf, dim_location_sdf, dim_st_marker, load_id, loaded_on)

# Insert new rows
nr_fact_parking.write.mode("append").insertInto(f"`{catalogname}`.dw.fact_parking")

# COMMAND ----------

dbutils.notebook.exit("success")
