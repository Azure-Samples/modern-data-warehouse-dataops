# Databricks notebook source
# MAGIC %pip install great-expectations==0.14.12
# MAGIC %pip install opencensus-ext-azure==1.1.7

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

# Insert new rows
t_parkingbay_sdf.write.mode("append").insertInto("interim.parking_bay")
t_sensordata_sdf.write.mode("append").insertInto("interim.sensor")

# Insert bad rows
t_parkingbay_malformed_sdf.write.mode("append").insertInto("malformed.parking_bay")
t_sensordata_malformed_sdf.write.mode("append").insertInto("malformed.sensor")


# COMMAND ----------

# MAGIC %md
# MAGIC ### Data Quality
# MAGIC The following uses the [Great Expectations](https://greatexpectations.io/) library. See [Great Expectation Docs](https://docs.greatexpectations.io/docs/) for more info.
# MAGIC 
# MAGIC **Note**: for simplication purposes, the [Expectation Suite](https://docs.greatexpectations.io/docs/terms/expectation_suite) is created inline. Generally this should be created prior to data pipeline execution, and only loaded during runtime and executed against a data [Batch](https://docs.greatexpectations.io/docs/terms/batch/) via [Checkpoint](https://docs.greatexpectations.io/docs/terms/checkpoint/).

# COMMAND ----------

import datetime
import pandas as pd
from ruamel import yaml
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.data_context import BaseDataContext
from great_expectations.data_context.types.base import (
    DataContextConfig,
    DatasourceConfig,
    FilesystemStoreBackendDefaults,
)
from pyspark.sql import SparkSession, Row


root_directory = "/dbfs/great_expectations/"

# 1. Configure DataContext
# https://docs.greatexpectations.io/docs/terms/data_context
data_context_config = DataContextConfig(
    datasources={
        "parkingbay_data_source": DatasourceConfig(
            class_name="Datasource",
            execution_engine={"class_name": "SparkDFExecutionEngine"},
            data_connectors={
                "parkingbay_data_connector": {
                    "module_name": "great_expectations.datasource.data_connector",
                    "class_name": "RuntimeDataConnector",
                    "batch_identifiers": [
                        "environment",
                        "pipeline_run_id",
                    ],
                }
            }
        )
    },
    store_backend_defaults=FilesystemStoreBackendDefaults(root_directory=root_directory)
)
context = BaseDataContext(project_config=data_context_config)


# 2. Create a BatchRequest based on parkingbay_sdf dataframe.
# https://docs.greatexpectations.io/docs/terms/batch
batch_request = RuntimeBatchRequest(
    datasource_name="parkingbay_data_source",
    data_connector_name="parkingbay_data_connector",
    data_asset_name="paringbaydataaset",  # This can be anything that identifies this data_asset for you
    batch_identifiers={
        "environment": "stage",
        "pipeline_run_id": "pipeline_run_id",
    },
    runtime_parameters={"batch_data": parkingbay_sdf},  # Your dataframe goes here
)


# 3. Define Expecation Suite and corresponding Data Expectations
# https://docs.greatexpectations.io/docs/terms/expectation_suite
expectation_suite_name = "parkingbay_data_exception_suite_basic"
context.create_expectation_suite(expectation_suite_name=expectation_suite_name, overwrite_existing=True)
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)
# Add Validatons to suite
# Check available expectations: validator.list_available_expectation_types()
# https://legacy.docs.greatexpectations.io/en/latest/autoapi/great_expectations/expectations/index.html
# https://legacy.docs.greatexpectations.io/en/latest/reference/core_concepts/expectations/standard_arguments.html#meta
validator.expect_column_values_to_not_be_null(column="meter_id")
validator.expect_column_values_to_not_be_null(column="marker_id")
validator.expect_column_values_to_be_of_type(column="rd_seg_dsc", type_="StringType")
validator.expect_column_values_to_be_of_type(column="rd_seg_id", type_="IntegerType")
# validator.validate() # To run run validations without checkpoint
validator.save_expectation_suite(discard_failed_expectations=False)



# 4. Configure a checkpoint and run Expectation suite using checkpoint
# https://docs.greatexpectations.io/docs/terms/checkpoint
my_checkpoint_name = "Parkingbay Data DQ"
checkpoint_config = {
    "name": my_checkpoint_name,
    "config_version": 1.0,
    "class_name": "SimpleCheckpoint",
    "run_name_template": "%Y%m%d-%H%M%S-my-run-name-template",
}
my_checkpoint = context.test_yaml_config(yaml.dump(checkpoint_config))
context.add_checkpoint(**checkpoint_config)
# Run Checkpoint passing in expectation suite.
checkpoint_result = context.run_checkpoint(
    checkpoint_name=my_checkpoint_name,
    validations=[
        {
            "batch_request": batch_request,
            "expectation_suite_name": expectation_suite_name,
        }
    ],
)


# COMMAND ----------

# MAGIC %md
# MAGIC ### Data Quality Metric Reporting
# MAGIC 
# MAGIC This parses the results of the checkpoint and sends it to AppInsights / Azure Monitor for reporting.

# COMMAND ----------

import logging
import time
from opencensus.ext.azure.log_exporter import AzureLogHandler

logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(connection_string=dbutils.secrets.get(scope = "storage_scope", key = "applicationInsightsConnectionString")))

result_dic = checkpoint_result.to_json_dict()
key_name=[key for key in result_dic['run_results'].keys()][0]
results = result_dic['run_results'][key_name]['validation_result']['results']

checks = {'check_name':checkpoint_result['checkpoint_config']['name'],'pipelinerunid':loadid}
for i in range(len(results)):
    validation_name= results[i]['expectation_config']['expectation_type'] + "_on_" + results[i]['expectation_config']['kwargs']['column']
    checks[validation_name]=results[i]['success']
    
properties = {'custom_dimensions': checks}

if checkpoint_result.success is True:
  logger.setLevel(logging.INFO)  
  logger.info('verifychecks', extra=properties)
else:
  logger.setLevel(logging.ERROR)
  logger.error('verifychecks', extra=properties)

time.sleep(16)


# COMMAND ----------

dbutils.notebook.exit("success")
