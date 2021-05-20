# Databricks notebook source
# MAGIC %md
# MAGIC # Tests

# COMMAND ----------

# MAGIC %run ./../main_notebook

# COMMAND ----------

# Arrange
df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])

expected_df = spark.createDataFrame([('Fiji Apple', 'Red', 7.0), 
                           ('Banana', 'Yellow', 2.0),
                           ('Green Grape', 'Green', 4.0),
                           ('Red Grape', 'Red', 4.0),
                           ('Peach', 'Yellow', 6.0),
                           ('Orange', 'Orange', 4.0),
                           ('Green Apple', 'Green', 5.0)], 
                           ['Fruit', 'Color', 'Price'])

# Act
actual_df = double_price(df)

# Assert
assert actual_df.collect() == expected_df.collect()
