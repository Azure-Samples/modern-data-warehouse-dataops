# Databricks notebook source
# MAGIC %pip install -U nutter

# COMMAND ----------

# MAGIC %run ../module_b_notebook

# COMMAND ----------

df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])

expected_df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5, 10.0), 
                           ('Banana', 'Yellow', 1.0, 10.0),
                           ('Green Grape', 'Green', 2.0, 10.0),
                           ('Red Grape', 'Red', 2.0, 10.0),
                           ('Peach', 'Yellow', 3.0,  10.0),
                           ('Orange', 'Orange', 2.0, 10.0),
                           ('Green Apple', 'Green', 2.5, 10.0)], 
                           ['Fruit', 'Color', 'Price', 'Amount'])

# COMMAND ----------

from runtime.nutterfixture import NutterFixture, tag

default_timeout = 600

class Test1Fixture(NutterFixture):
  def __init__(self):
    self.actual_df = None
    NutterFixture.__init__(self)
    
  def run_test_add_mount(self):
    self.actual_df = add_mount(df, 10)
    
  def assertion_test_add_mount(self):
    assert(self.actual_df.collect() == expected_df.collect())

  def after_test_add_mount(self):
    print('done')

# COMMAND ----------

result = Test1Fixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
is_job = dbutils.notebook.entry_point.getDbutils().notebook().getContext().currentRunId().isDefined()
if is_job:
  result.exit(dbutils)
