# Databricks notebook source
df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])

# COMMAND ----------

from pyspark.sql import DataFrame
from pyspark.sql.functions import col

def double_price(df: DataFrame):
  return df.select('Fruit', 'Color', (col('Price') * 2).alias('Price'))
  
double_price_df = double_price(df)
display(double_price_df)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Test

# COMMAND ----------

expected_df = spark.createDataFrame([('Fiji Apple', 'Red', 7.0), 
                           ('Banana', 'Yellow', 2.0),
                           ('Green Grape', 'Green', 4.0),
                           ('Red Grape', 'Red', 4.0),
                           ('Peach', 'Yellow', 6.0),
                           ('Orange', 'Orange', 4.0),
                           ('Green Apple', 'Green', 5.0)], 
                           ['Fruit', 'Color', 'Price'])

assert double_price_df.collect() == expected_df.collect()
