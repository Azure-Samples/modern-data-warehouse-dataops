# Databricks notebook source
# MAGIC %run ../notebooks/main_notebook

# COMMAND ----------

from pyspark.sql import Row
from runtime.nutterfixture import NutterFixture


class DoublePriceUTFixture(NutterFixture):
    def before_all(self):
      self._prepare_test_data()
  
    def run_double_price(self):
      self.double_price_df_a = double_price(self.df)
      dbutils.notebook.run('../notebooks/main_notebook', 32000)      
      self.double_price_df_b = spark.sql("select * from expected")
      
    def assertion_double_price(self):
      assert self.double_price_df_a.collect() == self.expected_df.collect()
      assert self.double_price_df_b.count() == self.expected_df.count()
      
    def after_all(self):
      spark.sql("DROP TABLE IF EXISTS expected")
        
    def _prepare_test_data(self):
      self.df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])
      self.expected_df = spark.createDataFrame([('Fiji Apple', 'Red', 7.0), 
                           ('Banana', 'Yellow', 2.0),
                           ('Green Grape', 'Green', 4.0),
                           ('Red Grape', 'Red', 4.0),
                           ('Peach', 'Yellow', 6.0),
                           ('Orange', 'Orange', 4.0),
                           ('Green Apple', 'Green', 5.0)], 
                           ['Fruit', 'Color', 'Price'])
      
result = DoublePriceUTFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
#result.exit(dbutils)


# COMMAND ----------


