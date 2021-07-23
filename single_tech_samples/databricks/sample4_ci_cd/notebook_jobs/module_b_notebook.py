# Databricks notebook source
from pyspark.sql import DataFrame
from pyspark.sql import functions as F

def add_mount(df: DataFrame, var_amount):
  return df.withColumn("Amount", F.lit(var_amount))

