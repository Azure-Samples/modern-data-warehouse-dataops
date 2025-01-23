# Databricks notebook source
import os
import datetime

# For testing
# Replace values before testing
stgaccountname=""
existing_data=""
base_path = f"abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/lnd/{existing_data}"
parkingbay_filepath = os.path.join(base_path, "MelbParkingBayData.json")
sensors_filepath = os.path.join(base_path, "MelbParkingSensorData.json")

# COMMAND ----------

parkingbay_sdf = spark.read\
  .option("multiLine", True)\
  .json(parkingbay_filepath)
sensordata_sdf = spark.read\
  .option("multiLine", True)\
  .json(sensors_filepath)

# COMMAND ----------

display(parkingbay_sdf)

# COMMAND ----------

display(sensordata_sdf)

# COMMAND ----------

display(sensordata_sdf)