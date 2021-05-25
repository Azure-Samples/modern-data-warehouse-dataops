# Databricks notebook source
from pyspark.sql import DataFrame
from pyspark.sql.functions import col

def double_price(df: DataFrame):
  return df.select('Fruit', 'Color', (col('Price') * 2).alias('Price'))

# COMMAND ----------

display(double_price(spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])))
