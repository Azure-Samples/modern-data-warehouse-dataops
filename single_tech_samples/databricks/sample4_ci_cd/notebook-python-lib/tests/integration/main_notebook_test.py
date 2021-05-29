# Databricks notebook source

# COMMAND ----------
# MAGIC  %pip install nutter

# COMMAND ----------

from pyspark.sql import Row, SparkSession
from runtime.nutterfixture import NutterFixture, tag

class DataAggregatorUTFixture(NutterFixture):
    def before_all(self):
      self._prepare_test_data()

    def run_data_aggregator(self):
      dbutils.notebook.run('../../notebooks/main_notebook', 600)
      self.litres_df_expected = spark.sql("select * from expected")

    def assertion_data_aggregator(self):
      assert self.litres_df_expected.count() == self.expected_df.count()

    def after_all(self):
      spark.sql("DROP TABLE IF EXISTS expected")

    def _prepare_test_data(self):
      test_data = [
            # pipe_id, start_time, end_time, litres_pumped
            (1, '2021-05-18 01:05:32', '2021-05-18 01:09:13', 10),
            (2, '2021-05-18 01:09:14', '2021-05-18 01:14:17', 20),
            (1, '2021-05-18 01:14:18', '2021-05-18 01:15:58', 30),
            (2, '2021-05-18 01:15:59', '2021-05-18 01:18:26', 40),
            (1, '2021-05-18 01:18:27', '2021-05-18 01:26:26', 60),
            (3, '2021-05-18 01:26:27', '2021-05-18 01:38:57', 60)
      ]
      test_data = [
         {
               'pipe_id': row[0],
               'start_time': row[1],
               'end_time': row[2],
               'litres_pumped': row[3]
         } for row in test_data
      ]
      self.test_df = spark.createDataFrame(map(lambda x: Row(**x), test_data))
      self.expected_df = spark.createDataFrame([(1, 800, 100, 0.12),
                           (2, 450, 60, 0.13),
                           (3, 750, 60, 0.08)],
                           ['pipe_id', 'total_duration_seconds', 'total_litres_pumped', 'avg_litres_per_second'])

result = DataAggregatorUTFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)


# COMMAND ----------
