# Databricks notebook source
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

JOB_TYPE = 'stream'

PACKAGE_NAME = 'cddp_solution'

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: delete job

# COMMAND ----------

def delete_job(job_id):
    success = False
    
    api_command = '/jobs/delete'
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
        print(f"Delete failed! job id: '{job_id}'")
        raise Exception(response.content)
    
    return success

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
        print("Delete failed!")
        raise Exception(response.content)
    
    return success

# COMMAND ----------

# MAGIC %md
# MAGIC ## Func: check if job is running

# COMMAND ----------

def is_running(job_id):
    is_running = False
    api_command = '/jobs/runs/list'
    url = f"https://{INSTANCE_ID}{API_VERSION}{api_command}"
    headers = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}

    params ={"job_id": job_id, "active_only": "true"}
    
    response = requests.get(
        url = url, 
        params = params,
        headers = headers)

    result = json.loads(response.text)
    
    if response.status_code == 200:
        if "runs" in result.keys() and len(result["runs"]) > 0 :
                is_running = True
        else:
            print("Not running")
    else:
        # raise Exception(response.content)
        is_running = False
    
    return is_running

# COMMAND ----------

# MAGIC %md
# MAGIC ## Read configs from delta table

# COMMAND ----------

# read configs from table
runner_config_df = spark.table("default.runner_config")
job_config_df =  spark.table("default.job_config")

job_config_tb = DeltaTable.forPath(spark, f"{PATH_TABLES}/job_config");

config_df = runner_config_df.join(job_config_df,
                          (runner_config_df.source_system == job_config_df.source_system) 
                        & (runner_config_df.customer_id == job_config_df.customer_id)
                        & (job_config_df.job_type == JOB_TYPE),
                        "inner")

display(config_df)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC ## Create/Trigger the streaming Job
# MAGIC For each row of the above config table,
# MAGIC 
# MAGIC - if job not existed yet
# MAGIC   - create the job
# MAGIC - if job already exist
# MAGIC   - check if the job is still running/if there is new version of config
# MAGIC      - if yes, recreate the job

# COMMAND ----------


# for each config record, create the job
for row in config_df.collect():

    config_json = row["config_json"]
    job_id = row["job_id"]
    
    source_system = row["source_system"]
    customer_id = row["customer_id"]
    key = f"{source_system}.{customer_id}.{JOB_TYPE}"
    
    tasks = row["tasks"]

    need_new = False
    
    con_find_job = f"source_system = '{source_system}' and customer_id = '{customer_id}' and job_type = '{JOB_TYPE}'"
    
    if job_id is None:
        print(f"Job for `{key}` not existed yet")
        need_new = True
    else:
        
        print(f"Found existing job for '{key}':{job_id}")
        
        # Check if real job exists
        if not is_running(job_id):
            print(f"Job {job_id}: is not Running")
            need_new = True
            
        if row["job_created_at"] is not None and row["config_updated_at"] is not None:
            if row["job_created_at"] < row["config_updated_at"]:
                # recreate the job
                print(f"New version of config detected for `{key}`")
                need_new = True
            
        if need_new:
            delete_job(job_id)
            print(f"Deleted existing job for '{key}':{job_id}")
            
    if need_new:
        # create new job
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

        if job_id is not None:
            trigger_job(job_id)
            print(f"Triggered job for '{key}':{job_id}")
        
