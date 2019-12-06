# Databricks notebook source
dbutils.widgets.text("infilefolder", "", "In - Folder Path")
infilefolder = dbutils.widgets.get("infilefolder")

dbutils.widgets.text("loadid", "", "Load Id")
loadid = dbutils.widgets.get("loadid")

# COMMAND ----------

from applicationinsights import TelemetryClient
tc = TelemetryClient(dbutils.secrets.get(scope = "storage_scope", key = "appinsights_key"))

# COMMAND ----------

import os
import datetime

# For testing
# infilefolder = 'datalake/data/lnd/2019_03_11_01_38_00/'
load_id = loadid
loaded_on = datetime.datetime.now()
base_path = os.path.join('dbfs:/mnt/datalake/data/lnd/', infilefolder)
parkingbay_filepath = os.path.join(base_path, "MelbParkingBayData.json")
sensors_filepath = os.path.join(base_path, "MelbParkingSensorData.json")


# COMMAND ----------

import ddo_transform.standardize as s

# Retrieve schema
parkingbay_schema = s.get_schema("in_parkingbay_schema")
sensordata_schema = s.get_schema("in_sensordata_schema")

# Read data
parkingbay_sdf = spark.read\
  .schema(parkingbay_schema)\
  .option("badRecordsPath", os.path.join(base_path, "__corrupt", "MelbParkingBayData"))\
  .option("multiLine", True)\
  .json(parkingbay_filepath)
sensordata_sdf = spark.read\
  .schema(sensordata_schema)\
  .option("badRecordsPath", os.path.join(base_path, "__corrupt", "MelbParkingSensorData"))\
  .option("multiLine", True)\
  .json(sensors_filepath)


# Standardize
t_parkingbay_sdf, t_parkingbay_malformed_sdf = s.standardize_parking_bay(parkingbay_sdf, load_id, loaded_on)
t_sensordata_sdf, t_sensordata_malformed_sdf = s.standardize_sensordata(sensordata_sdf, load_id, loaded_on)

# Insert new rows
t_parkingbay_sdf.write.mode("append").insertInto("interim.parking_bay")
t_sensordata_sdf.write.mode("append").insertInto("interim.sensor")

# Insert bad rows
t_parkingbay_malformed_sdf.write.mode("append").insertInto("malformed.parking_bay")
t_sensordata_malformed_sdf.write.mode("append").insertInto("malformed.sensor")


# COMMAND ----------

# MAGIC %md
# MAGIC ### Metrics

# COMMAND ----------

parkingbay_count = t_parkingbay_sdf.count()
sensordata_count = t_sensordata_sdf.count()
parkingbay_malformed_count = t_parkingbay_malformed_sdf.count()
sensordata_malformed_count = t_sensordata_malformed_sdf.count()

tc.track_event('Standardize : Completed load', 
               properties={'parkingbay_filepath': parkingbay_filepath, 
                           'sensors_filepath': sensors_filepath,
                           'load_id': load_id 
                          },
               measurements={'parkingbay_count': parkingbay_count,
                             'sensordata_count': sensordata_count,
                             'parkingbay_malformed_count': parkingbay_malformed_count,
                             'sensordata_malformed_count': sensordata_malformed_count
                            })
tc.flush()

# COMMAND ----------

dbutils.notebook.exit("success")
