# Databricks notebook source
# MAGIC %pip install great-expectations==0.14.12
# MAGIC %pip install opencensus-ext-azure==1.1.3

# COMMAND ----------

dbutils.widgets.text("loadid", "", "Load Id")
loadid = dbutils.widgets.get("loadid")

# COMMAND ----------

import datetime
import os
from pyspark.sql.functions import col, lit
import ddo_transform.transform as t
import ddo_transform.util as util

load_id = loadid
loaded_on = datetime.datetime.now()
base_path = 'dbfs:/mnt/datalake/data/dw/'


sensordata_non_functional_bay = spark.read.table("interim.sensor").filter(col('load_id') == lit(load_id))
sensordata_non_functional_bay.createOrReplaceTempView("sensordata_non_functional_bay")
non_functional_bay=sql("""select distinct bay_id, 'non-functional' as status from sensordata_non_functional_bay order by bay_id desc limit 100""")
util.save_overwrite_unmanaged_table(spark, non_functional_bay, table_name="dw.non_functional_bay", path=os.path.join(base_path, "non_functional_bay"))
