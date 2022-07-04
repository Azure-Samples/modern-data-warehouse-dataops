# Databricks notebook source
# MAGIC %pip install great-expectations==0.14.12
# MAGIC %pip install opencensus-ext-azure==1.1.3

# COMMAND ----------

dbutils.widgets.text("infilefolder", "", "In - Folder Path")
infilefolder = dbutils.widgets.get("infilefolder")

dbutils.widgets.text("loadid", "", "Load Id")
loadid = dbutils.widgets.get("loadid")

# COMMAND ----------

import os
import datetime

# For testing
# infilefolder = '2022_03_23_10_28_02/'
# loadid = 1

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

# COMMAND ----------

from pyspark.sql.functions import col, lit
import ddo_transform.transform as t
import ddo_transform.util as util

t_parkingbay_sdf.createOrReplaceTempView("parking_non_functional_bay")
t_sensordata_sdf.createOrReplaceTempView("sensor_non_functional_bay")

# COMMAND ----------

non_functional_bay=sql("""select distinct pf.bay_id, 'non-functional' as status from parking_non_functional_bay pf inner join sensor_non_functional_bay sf on pf.bay_id=sf.bay_id  order by pf.bay_id desc limit 100""")
util.save_overwrite_unmanaged_table(spark, non_functional_bay, table_name="dw.non_functional_bay", path=os.path.join(base_path, "non_functional_bay"))

# COMMAND ----------


