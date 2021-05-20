# Databricks notebook source
# MAGIC %run ../notebooks/module_a_notebook

# COMMAND ----------

dbutils.notebook.run('../notebooks/module_b_notebook', 32000) 
