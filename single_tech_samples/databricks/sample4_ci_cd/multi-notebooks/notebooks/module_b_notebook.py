# Databricks notebook source
df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])
df.createOrReplaceTempView("origin")

# COMMAND ----------

# MAGIC %sql 
# MAGIC DROP TABLE IF EXISTS expected;
# MAGIC CREATE TABLE IF NOT EXISTS expected AS
# MAGIC Select
# MAGIC   Fruit,
# MAGIC   Color,
# MAGIC   Price * 2 as Price
# MAGIC from
# MAGIC   origin

# COMMAND ----------


