# Databricks notebook source
import os
import datetime

# For testing
base_path = 'dbfs:/mnt/datalake/data/lnd/2019_10_06_05_54_25'
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
