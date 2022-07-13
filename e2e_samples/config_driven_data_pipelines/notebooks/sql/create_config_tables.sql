-- Databricks notebook source
-- MAGIC %md
-- MAGIC ## Step 1. Clear existing delta table files

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dbutils.fs.rm("/FileStore/cddp/tables", True)
-- MAGIC dbutils.fs.rm("/__data_storage__", True)
-- MAGIC dbutils.fs.rm("/tmp", True)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 2. Create Table of runner config 
-- MAGIC runner config table saves configs 

-- COMMAND ----------

DROP TABLE default.runner_config;
CREATE TABLE IF NOT EXISTS default.runner_config (
  id INT,
  source_system STRING,
  customer_id STRING,
  config_json STRING,
  config_updated_at timestamp
) USING DELTA
Location '/FileStore/cddp/tables/runner_config';

-- COMMAND ----------

-- insert into default.runner_config
-- values (1, "cddp_fruit_app", "customer_2", '{"customer_id": "customer_2", "serving_data_storage_path": "serving_data_storage", "event_data_curation": [{"sql": "select m.ID, m.Fruit, count(m.ID) as sales_count, sum(m.Price*m.amount) as sales_total from fruits_events m   group by m.ID, m.Fruit", "target": "fruits_sales", "partition_keys": ""}], "event_data_source": {"name": "event-hub", "type": "local", "format": "json", "table_name": "events", "location": "customer_2/mock_events/"}, "event_data_transform_partition_keys": "ID", "event_data_storage_path": "event_data_storage", "event_data_table_name": "fruits_events", "event_data_transform_function": "cddp_fruit_app_customers_customer_2.event_transformation", "master_data_source": [{"name": "raw_data", "type": "csv", "table_name": "INPUT_DATA_VIEW", "data": "ID,shuiguo,yanse,jiage\\n1,Red Grape,Red, 2.5\\n2,Peach,Yellow,3.5\\n3,Orange,Orange, 2.3\\n4,Green Apple,Green, 3.5\\n5,Fiji Apple,Red, 3.4 \\n6,Banana,Yellow, 1.2\\n7,Green Grape, Green,2.2"}], "master_data_transform": [{"function": "cddp_fruit_app_customers_customer_2.master_transformation", "target": "fruits"}], "master_data_storage_path": "master_data_storage", "master_data_transform_function": "cddp_fruit_app_customers_customer_2.master_transformation"}', now());


-- COMMAND ----------

select * from default.runner_config

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 3. Create table for jobs

-- COMMAND ----------

DROP TABLE default.job_config;
CREATE TABLE IF NOT EXISTS default.job_config (
  id INT,
  source_system STRING,
  customer_id STRING,
  job_type STRING,
  tasks ARRAY<STRING>,
  job_id STRING,
  job_status STRING,
  whl STRING,
  whl_version STRING,
  job_created_at timestamp
) USING DELTA
Location '/FileStore/cddp/tables/job_config';

-- COMMAND ----------

-- insert into default.job_config
-- values (1, "cddp_fruit_app", "customer_2", "batch", array("master_data_transform", "master_data_ingest"), null, null,null,null, null);

-- insert into default.job_config
-- values (1, "cddp_fruit_app", "customer_2", "stream", array("event_data_transform"), null, null,null,null, null);


-- COMMAND ----------

select * from default.job_config;
