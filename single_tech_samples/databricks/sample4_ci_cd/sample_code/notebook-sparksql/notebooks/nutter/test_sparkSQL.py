# Databricks notebook source
# MAGIC  %pip install nutter

# COMMAND ----------

from runtime.nutterfixture import NutterFixture, tag
class MyTestFixture(NutterFixture):
   def assertion_test_name(self):
      some_tbl = sqlContext.sql('SELECT COUNT(*) FROM US_POPULATION')
      assert (some_tbl.first()[0] > 1)
print("Starting Test")
result = MyTestFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)

# COMMAND ----------