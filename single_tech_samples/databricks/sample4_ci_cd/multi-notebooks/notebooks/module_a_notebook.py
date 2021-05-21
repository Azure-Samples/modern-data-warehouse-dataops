# Databricks notebook source
from pyspark.sql import DataFrame
from pyspark.sql.functions import col

def double_price(df: DataFrame):
  return df.select('Fruit', 'Color', (col('Price') * 2).alias('Price'))
  
