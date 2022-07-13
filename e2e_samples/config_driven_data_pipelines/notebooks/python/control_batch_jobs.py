# Databricks notebook source
# MAGIC %md
# MAGIC ## Settings

# COMMAND ----------

import requests
import json
import datetime
from delta.tables import *
from pyspark.sql.functions import *

INSTANCE_ID = '<instance-id>'
CLUSTER_ID = '<cluster-id>'
API_VERSION = '/api/2.1'

TOKEN = '<token>'

PATH_TABLES = '/FileStore/cddp/tables'
PATH_CONFIG_FILES = '/FileStore/cddp/configs'

JOB_TYPE = 'batch'

PACKAGE_NAME = 'cddp_solution'

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: create job  
# MAGIC Create a new job with a python wheel task.
# MAGIC Required parameters,
# MAGIC - `uc_id`: name to create the job
# MAGIC - `tasks`: list of names of the entry point to run (need to set when build the wheel name)
# MAGIC - `params`: 

# COMMAND ----------

def create_job(uc_id, params, tasks):
    job_id = None
    
    api_command = '/jobs/create'
    url = f"https://{INSTANCE_ID}{API_VERSION}{api_command}"
    headers = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}
  
    wheel_tasks = []
    prev_task = None
    for task in tasks:
        wheel_task = {
              "task_key": task,
              "description": f"Batch job task",
              "existing_cluster_id": f"{CLUSTER_ID}",
              "python_wheel_task" : {
                  "package_name": PACKAGE_NAME,
                  "entry_point": task,
                  "parameters": params,
              },
              "timeout_seconds": 6000,
              "max_retries": 3,
              "min_retry_interval_millis": 2000,
              "retry_on_timeout": True
          }
        
        if prev_task:
            wheel_task["depends_on"] = [ { "task_key": prev_task } ]
        
        wheel_tasks.append(wheel_task)
        
        prev_task = task
        
    
    body_json ={
      "name": uc_id,
      "tasks": wheel_tasks
    }
    
    response = requests.post(
        url = url, 
        headers = headers, 
        data = json.dumps(body_json,default = str))

    result = json.loads(response.text)
    
    if response.status_code == 200:
        job_id = result['job_id']
    else:
        print("job failed!")
        raise Exception(response.content)
    
    return job_id

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: trigger job

# COMMAND ----------

def trigger_job(job_id):
    success = False
    api_command = '/jobs/run-now'
    url = f"https://{INSTANCE_ID}{API_VERSION}{api_command}"
    headers = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}

    body_json ={"job_id": job_id}
    
    response = requests.post(
        url = url, 
        headers = headers, 
        data = json.dumps(body_json,default = str))

    result = json.loads(response.text)
    
    if response.status_code == 200:
        success = True
    else:
        print("triggered failed!")
        raise Exception(response.content)
    
    return success

# COMMAND ----------

# MAGIC %md
# MAGIC ## Read configs from delta table

# COMMAND ----------

# 1. read configs from table
runner_config_df = spark.table("default.runner_config")
job_config_df =  spark.table("default.job_config").where(col("job_type") == JOB_TYPE)

job_config_tb = DeltaTable.forPath(spark, f"{PATH_TABLES}/job_config")

config_df = runner_config_df.join(job_config_df,
                          (runner_config_df.source_system == job_config_df.source_system) 
                        & (runner_config_df.customer_id == job_config_df.customer_id),
                        "inner")

display(config_df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create/Trigger the Job  
# MAGIC For each row of the above config table,
# MAGIC - output config.json to `config_path`
# MAGIC - if job not existed yet
# MAGIC   - create the job which has a python wheel task
# MAGIC - if job already exist
# MAGIC   - run the job

# COMMAND ----------

# 2. for each config record (source_sytem/customer)
for row in config_df.collect():

    config_json = row["config_json"]
    job_id = row["job_id"]

    source_system = row["source_system"]
    customer_id = row["customer_id"]
    key = f"{source_system}.{customer_id}.{JOB_TYPE}"
    
    tasks = row["tasks"]
    print(f"-------------{key}------------------")

    if row["job_created_at"] is not None and row["config_updated_at"] is not None:
        if row["job_created_at"] < row["config_updated_at"]:
            print(f"New version of config detected for `{key}`")

    # 2.1 output config.json to `config_path`
    config_path = f"{PATH_CONFIG_FILES}/{source_system}_customers/{customer_id}/config.json"
    print(f"Config.json generated at: {config_path}")
    dbutils.fs.put(config_path, config_json, True)
    
    con_find_job = f"source_system = '{source_system}' and customer_id = '{customer_id}' and job_type = '{JOB_TYPE}'"
    
    # 2.2 create the job if it does not exists yet.
    if job_id is None:
        print(f"Job for `{key}` not existed yet")
        
        # pass the config.json path to task
        params = [
            source_system,
            customer_id,
            f"/dbfs{PATH_CONFIG_FILES}"]
        
        job_id = create_job(key, params, tasks)
        print(f"Created job for '{key}':{job_id}")
        
        # Update job config table with new job_id 
        job_config_tb.update(
            condition = con_find_job,
             set = { "job_id": f"'{job_id}'", "job_created_at":"now()" })
    else:
        print(f"Found existing job for '{key}':{job_id}")
    
    # 2.3 trigger the job
    if job_id is not None:
        
        trigger_job(job_id)
        print(f"Triggered job for '{key}':{job_id}")

