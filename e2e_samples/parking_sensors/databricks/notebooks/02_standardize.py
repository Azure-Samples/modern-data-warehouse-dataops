# Databricks notebook source
# MAGIC %md
# MAGIC ## Libraries

# COMMAND ----------

# MAGIC %pip install opencensus-ext-azure==1.1.14

# COMMAND ----------

# MAGIC %md
# MAGIC ## Parameters

# COMMAND ----------

dbutils.widgets.text("infilefolder", "", "In - Folder Path")
infilefolder = dbutils.widgets.get("infilefolder")

dbutils.widgets.text("loadid", "", "Load Id")
loadid = dbutils.widgets.get("loadid")

dbutils.widgets.text("catalogname", "", "Catalog Name")
catalogname = dbutils.widgets.get("catalogname")

dbutils.widgets.text("stgaccountname", "", "Storage Account Name")
stgaccountname = dbutils.widgets.get("stgaccountname")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup File Paths

# COMMAND ----------

import os
import datetime

# For testing
#infilefolder = '2022_03_23_10_28_02/'
#loadid = 1
#catalogname = "mdwdops-tsl16-data-catalog-dev"
#stgaccountname = "mdwdopsstdevtsl16"

load_id = loadid
loaded_on = datetime.datetime.now()

abfss_path= f"""abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/lnd/"""
base_path = os.path.join(abfss_path,infilefolder)
parkingbay_filepath = os.path.join(base_path, "ParkingLocationData.json")
sensors_filepath = os.path.join(base_path, "ParkingSensorData.json")


# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup Catalog

# COMMAND ----------

# Use the catalog
spark.sql(f"USE CATALOG `{catalogname}`")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Standardize Code

# COMMAND ----------

import ddo_transform.standardize as s

# Retrieve schema
parkingbay_schema = s.get_schema("in_parkingbay_schema")
sensordata_schema = s.get_schema("in_sensordata_schema")

# Read data
parkingbay_sdf = spark.read\
  .schema(parkingbay_schema)\
  .option("badRecordsPath", os.path.join(base_path, "__corrupt", "ParkingLocationData"))\
  .option("multiLine", True)\
  .json(parkingbay_filepath)
sensordata_sdf = spark.read\
  .schema(sensordata_schema)\
  .option("badRecordsPath", os.path.join(base_path, "__corrupt", "ParkingSensorData"))\
  .option("multiLine", True)\
  .json(sensors_filepath)


# Standardize
t_parkingbay_sdf, t_parkingbay_malformed_sdf = s.standardize_parking_bay(parkingbay_sdf, load_id, loaded_on)
t_sensordata_sdf, t_sensordata_malformed_sdf = s.standardize_sensordata(sensordata_sdf, load_id, loaded_on)

# Insert new rows
t_parkingbay_sdf.write.mode("append").insertInto(f"`{catalogname}`.interim.parking_bay")
t_sensordata_sdf.write.mode("append").insertInto(f"`{catalogname}`.interim.sensor")

# Insert bad rows
t_parkingbay_malformed_sdf.write.mode("append").insertInto(f"`{catalogname}`.malformed.parking_bay")
t_sensordata_malformed_sdf.write.mode("append").insertInto(f"`{catalogname}`.malformed.sensor")

# COMMAND ----------

dbutils.notebook.exit("success")