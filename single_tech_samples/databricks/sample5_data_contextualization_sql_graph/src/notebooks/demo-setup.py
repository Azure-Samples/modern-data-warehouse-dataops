# Databricks notebook source
dbutils.fs.rm("/mnt/honeywell/raw/tbl_alarm_master", True)
dbutils.fs.rm("/mnt/honeywell/table_commit_version", True)

# COMMAND ----------

# MAGIC %sql
# MAGIC drop table if exists tbl_alarm_master;
# MAGIC drop table if exists table_commit_version;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE TABLE tbl_alarm_master (alarm_id INT, alarm_type STRING, alarm_desc STRING, valid_from TIMESTAMP, valid_till TIMESTAMP) 
# MAGIC USING DELTA
# MAGIC LOCATION '/mnt/honeywell/raw/tbl_alarm_master'
# MAGIC TBLPROPERTIES (delta.enableChangeDataFeed = true)

# COMMAND ----------

# MAGIC %sql
# MAGIC INSERT INTO tbl_alarm_master VALUES (1, "Carbon Monoxide Warning", "TAG_1", "2023-01-01 00:00:00.0000", "2999-12-31 23:59:59.0000"),
# MAGIC (2, "Fire Warning", "TAG_2", "2023-01-01 00:00:00.0001", "2999-12-31 23:59:59.0000"),
# MAGIC (3, "Flood Warning", "TAG_3",  "2023-01-01 00:00:00.0002", "2999-12-31 23:59:59.0000")

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE TABLE table_commit_version (table_name STRING, last_commit_version LONG, updated_at TIMESTAMP)
# MAGIC USING DELTA
# MAGIC LOCATION '/mnt/honeywell/table_commit_version'

# COMMAND ----------

# MAGIC %sql
# MAGIC INSERT INTO table_commit_version VALUES('tbl_alarm_master', 1, current_timestamp())

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from table_changes('tbl_alarm_master',1)

# COMMAND ----------

# MAGIC %sql
# MAGIC INSERT INTO tbl_alarm_master VALUES (4, "Flood Warning", "TAG_4", "2023-01-01 00:00:00.0000", "2999-12-31 23:59:59.0000");
