# Databricks notebook source
# REPLACE THIS
your_storage_account_name=''

# COMMAND ----------

# For credential passthrough
configs = {
    "fs.azure.account.auth.type": "CustomAccessToken",
    "fs.azure.account.custom.token.provider.class": spark.conf.get("spark.databricks.passthrough.adls.gen2.tokenProviderClassName")
}

# Confirm if you can access deltalake. Update the path with the name of your storage account.
file_path = f"abfss://datalake@{your_storage_account_name}.dfs.core.windows.net/lc_loan"
dbutils.fs.ls(file_path)

# COMMAND ----------

# List versions
display(spark.sql(f"DESCRIBE HISTORY delta.`{file_path}`"))

# COMMAND ----------

# Load from specific version
load_data = spark.read.format("delta").option("versionAsOf", 0).load(file_path)
display(load_data)
