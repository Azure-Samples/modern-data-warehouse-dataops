# Databricks notebook source
# MAGIC %md
# MAGIC ## Func: Get all wheel libraries from the cluster

# COMMAND ----------

import os
import requests
import json

INSTANCE_ID = "<instance-id>"
CLUSTER_ID = "<cluster_id>"
API_VERSION = "/api/2.0"
TOKEN = "<token>"


def get_all_whls():
    whls = []
    url = f"https://{INSTANCE_ID}{API_VERSION}/libraries/cluster-status?cluster_id={CLUSTER_ID}"
    headers = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}
    response = requests.get(url = url, headers = headers )
    
    result = json.loads(response.text)
    
    if response.status_code == 200:
        for lib in result["library_statuses"]:
            if lib["status"] == "INSTALLED" and "whl" in lib["library"]:
                whl = lib["library"]["whl"]
                whl = whl.split(":")
                whl = "/"+whl[0]+whl[1]
                whls.append(whl)
    else:
        print("query failed!")
        raise Exception(response.content)
    
    return whls
    

print(get_all_whls())

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: Get souce_system, customer, version from the wheel file
# MAGIC Required parameters:
# MAGIC - `whl`: the path to the wheel file

# COMMAND ----------

from wheel_inspect import inspect_wheel

def get_source_system_customer(whl):
    source_system = None
    customer = None
    version = None
    output = inspect_wheel(whl)
    
    # Read source_system and customer info
    if "keywords" in output["dist_info"]["metadata"]:
        keywords = output["dist_info"]["metadata"]["keywords"]
        if keywords is not None:
            keywords = keywords.split(",")
            if len(keywords) == 2:
                source_system = keywords[0]
                customer = keywords[1]
    
    # Read version info
    if "version" in output["dist_info"]["metadata"]:
        version = output["dist_info"]["metadata"]["version"]
        if version is None:
            version = ""
    
    return source_system, customer, version
    

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: Get the Config.json from the wheel file
# MAGIC Required parameters:
# MAGIC - `source_system`: source system name, e.g. 'fruit'
# MAGIC - `customer`: customer name, e.g. 'customer_1'
# MAGIC - `whl`: the path of the wheel file

# COMMAND ----------

import zipfile
 
def get_config(source_system, customer, whl):
    with zipfile.ZipFile(whl) as f:
        f.extractall("/dbfs/tmp")
    config = None
    with open(f"/dbfs/tmp/{source_system}_customers/{customer}/config.json", "r") as f:
        config = json.load(f)
    config = json.dumps(config)
    config = config.encode("unicode_escape").decode("utf-8")
    return config

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: Get the current id to support incremental identity
# MAGIC Should be replaced by using IDENITTY with Databricks runtime > 10.4
# MAGIC Required parameters:
# MAGIC - `id_col`: id column name
# MAGIC - `table`: table name

# COMMAND ----------

import datetime
from delta.tables import *
from pyspark.sql.functions import *  

def get_current_id(id_col, table):
    df = spark.sql("select max({})+1 from {}".format(id_col,table))
    if df.count()==1:
        if df.collect()[0][0] is not None:
            return df.collect()[0][0]
    else:
        raise Exception(f"Cannot get the current value of {id_col}")
    return 1

print(get_current_id("id","default.job_config"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: Upsert the runner_config table
# MAGIC TO enable the upsert action for config.json with single quotes.
# MAGIC
# MAGIC Required parameters:
# MAGIC - `config_df`: the new config dataframe

# COMMAND ----------

def upsert_runner_config(config_df):
    rc_table = DeltaTable.forName(spark, 'default.runner_config')
    rc_table.alias('t') \
      .merge(
        config_df.alias('d'),
        't.source_system = d.source_system and t.customer_id = d.customer_id'
      ) \
      .whenMatchedUpdate(set =
        {
          "config_json": "d.config_json",
          "config_updated_at": "current_timestamp()"
        }
      ) \
      .whenNotMatchedInsert(values =
        {
          "id": f"{get_current_id('id','default.runner_config')}",
          "source_system": "d.source_system",
          "customer_id": "d.customer_id",
          "config_json": "d.config_json",
          "config_updated_at": "current_timestamp()"
        }
      ) \
      .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Main onboarding process to check all newly installed wheel files
# MAGIC Onboarding business process:
# MAGIC - Get all wheel files installed on the databricks cluster
# MAGIC - For each of the wheel file:
# MAGIC   - Get its source_system, customer and version
# MAGIC   - Extract the config.json string
# MAGIC   - Insert or update the wheel file information in the configuration database

# COMMAND ----------

from packaging import version

whls = get_all_whls()

for whl in whls:
    source_system, customer, new_version = get_source_system_customer(whl)
    if source_system is None or customer is None:
        print(f"No source system or customer information from {whl}!")
        continue
    # Get the config.json
    config = get_config(source_system, customer, whl)
    print(config)
    new_df = spark.createDataFrame([(source_system, customer, config)],["source_system", "customer_id", "config_json"])
    df = spark.sql(f"SELECT * from default.job_config WHERE source_system='{source_system}' AND customer_id='{customer}'")
    if df.count()==0: # Insert a new record
        spark.sql("INSERT INTO default.job_config VALUES({}, '{}', '{}', 'batch',array('master_data_ingest','master_data_transform'), null, null, '{}', '{}', now())".format(get_current_id("id","default.job_config"),source_system, customer, whl, new_version))
        spark.sql("INSERT INTO default.job_config VALUES({}, '{}', '{}', 'stream',array('event_data_transform'), null, null, '{}', '{}', now())".format(get_current_id("id","default.job_config"),source_system, customer, whl, new_version))
        upsert_runner_config(new_df)
    else: # Update the existing record
        current_version = df.first()["whl_version"]
        if current_version is None:
            current_version =""
        if version.parse(new_version) > version.parse(current_version):
            spark.sql("UPDATE default.job_config SET whl='{}', whl_version='{}' WHERE source_system='{}' AND customer_id='{}'".format(whl,new_version,source_system,customer))
            upsert_runner_config(new_df)

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from default.job_config

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from default.runner_config