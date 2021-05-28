# Databricks notebook source

# COMMAND ----------

from common.module_b import int_to_str
print(int_to_str(1000))

# COMMAND ----------
from pyspark.sql import Row, SparkSession
from pyspark.sql.dataframe import DataFrame
from common.module_a import get_litres_per_second

spark = SparkSession.builder.appName("example-data-aggregator").getOrCreate()

test_data = [
            # pipe_id, start_time, end_time, litres_pumped
            (1, '2021-02-01 01:05:32', '2021-02-01 01:09:13', 10),
            (2, '2021-02-01 01:09:14', '2021-02-01 01:14:17', 20),
            (1, '2021-02-01 01:14:18', '2021-02-01 01:15:58', 30),
            (2, '2021-02-01 01:15:59', '2021-02-01 01:18:26', 40),
            (1, '2021-02-01 01:18:27', '2021-02-01 01:26:26', 60),
            (3, '2021-02-01 01:26:27', '2021-02-01 01:38:57', 60)
        ]
test_data = [
	{
		'pipe_id': row[0],
		'start_time': row[1],
		'end_time': row[2],
		'litres_pumped': row[3]
	} for row in test_data
]
test_df = spark.createDataFrame(map(lambda x: Row(**x), test_data))
test_df.createOrReplaceTempView("origin")

# COMMAND ----------

# MAGIC %sql
# MAGIC DROP TABLE IF EXISTS original;
# MAGIC CREATE TABLE IF NOT EXISTS original AS
# MAGIC Select
# MAGIC   pipe_id,
# MAGIC   start_time,
# MAGIC   end_time,
# MAGIC   litres_pumped
# MAGIC from
# MAGIC   origin

# COMMAND ----------

output_df = get_litres_per_second(test_df)
output_df.createOrReplaceTempView("output")

# COMMAND ----------

# MAGIC %sql
# MAGIC DROP TABLE IF EXISTS expected;
# MAGIC CREATE TABLE IF NOT EXISTS expected AS
# MAGIC Select
# MAGIC   pipe_id,
# MAGIC   total_duration_seconds,
# MAGIC   total_litres_pumped,
# MAGIC   avg_litres_per_second
# MAGIC from
# MAGIC   output

# COMMAND ----------