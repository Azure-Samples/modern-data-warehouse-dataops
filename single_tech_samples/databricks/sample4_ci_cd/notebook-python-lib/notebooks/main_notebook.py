# Databricks notebook source

# COMMAND ----------

from pyspark.sql import Row, SparkSession
from pyspark.sql.dataframe import DataFrame

# COMMAND ----------
%run "../common/module_a"

# COMMAND ----------

test_data = [
            # pipe_id, start_time, end_time, litres_pumped
            (1, '2021-02-01 01:05:32', '2021-02-01 01:09:13', 24),
            (2, '2021-02-01 01:09:14', '2021-02-01 01:14:17', 41),
            (1, '2021-02-01 01:14:18', '2021-02-01 01:15:58', 11),
            (2, '2021-02-01 01:15:59', '2021-02-01 01:18:26', 13),
            (1, '2021-02-01 01:18:27', '2021-02-01 01:26:26', 45),
            (3, '2021-02-01 01:26:27', '2021-02-01 01:38:57', 15)
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
output_df = get_litres_per_second(test_df)
