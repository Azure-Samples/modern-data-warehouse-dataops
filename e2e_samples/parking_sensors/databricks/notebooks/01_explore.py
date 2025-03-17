# Databricks notebook source
import os
import datetime

# For testing
# Replace values before testing
#infilefolder = '2022_03_23_10_28_02/'
#stgaccountname = "stg_account_name"

abfss_path= f"""abfss://datalake@{stgaccountname}.dfs.core.windows.net/data/lnd/"""
base_path = os.path.join(abfss_path,infilefolder)
parkingbay_filepath = os.path.join(base_path, "ParkingLocationData.json")
sensors_filepath = os.path.join(base_path, "ParkingSensorData.json")


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