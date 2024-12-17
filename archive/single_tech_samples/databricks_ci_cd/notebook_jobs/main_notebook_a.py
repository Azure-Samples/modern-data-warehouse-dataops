# Databricks notebook source
from pyspark.sql import functions as F
from pyspark.sql import DataFrame
from common.module_a import add_mount
# COMMAND ----------


# define a method in the notebook
def double_price(df: DataFrame):
  return df.select('Fruit', 'Color', (F.col('Price') * 2).alias('Price'))

# COMMAND ----------

def transform_data(df: DataFrame): 
  default_timeout = 600
  # invoke a function in another notebook
  df = double_price(df)
  df = add_mount(df, 10)
  return df

# COMMAND ----------

df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])
df = transform_data(df)

display(df)

# COMMAND ----------

df.createOrReplaceTempView('MY_VIEW')

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from MY_VIEW
