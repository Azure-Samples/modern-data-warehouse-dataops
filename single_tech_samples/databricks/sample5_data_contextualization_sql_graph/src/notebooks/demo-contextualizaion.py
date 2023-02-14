# Databricks notebook source
jdbcUsername = "<Username>"
jdbcPassword = "<Password>"
jdbcHostname = "<Hostname>.database.windows.net"
jdbcPort = 1433
jdbcDatabase ="<DatabaseName>"

jdbc_url = f"jdbc:sqlserver://{jdbcHostname}:{jdbcPort};database={jdbcDatabase};user={jdbcUsername};password={jdbcPassword};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;"

pushdown_query = "(SELECT a.Alarm_Type, b.Asset_ID\
                   FROM Alarm a, belongs_to, Asset b, is_associated_with, Quality_System c\
                   WHERE MATCH (a-(belongs_to)->c-(is_associated_with)->b)) as new_tbl2"

ala2ass = spark.read \
        .format("jdbc") \
        .option("url", jdbc_url) \
        .option("dbtable", pushdown_query).load()


# COMMAND ----------

display(ala2ass)

# COMMAND ----------

from pyspark.sql.types import StructType, StructField, StringType, TimestampType, IntegerType
from pyspark.sql.functions import *
def save_df(df, table_name):
    df = df.withColumn("valid_from", current_timestamp())
    df = df.withColumn("valid_till", to_timestamp(lit("2099-12-31 23:59:59.0000") ,"yyyy-MM-dd HH:mm:ss.SSSS"))
    df.write.mode("overwrite").format("delta").option("path", "/mnt/honeywell/reference/{}".format(table_name)).option("overwriteSchema", "true").saveAsTable(table_name)

# COMMAND ----------

save_df(ala2ass, "ala2ass")

# COMMAND ----------

# MAGIC %sql
# MAGIC select *
# MAGIC   from tbl_alarm_master

# COMMAND ----------

def process_data(system): 
    # Get last_commit_version in table_commit_version for the data source table
    last_commit_version = spark.sql(f"select max(last_commit_version) as last_commit_version from table_commit_version where table_name='{system}'").collect()[0].asDict()['last_commit_version']
    # Get the max(_commit_version) from the table_changes
    max_commit_version = spark.sql(f"select max(_commit_version) as max_commit_version from table_changes('{system}',1)").collect()[0].asDict()['max_commit_version']
    
    # Query and process the newly added data since the last_commit_version
    df_tlb_change = spark.sql(f"select * from table_changes('{system}',{last_commit_version})")
    
    if(last_commit_version == max_commit_version + 1):
        return None
    
    df = spark.sql(f"select raw.alarm_id, raw.alarm_type, raw.alarm_desc, raw.valid_from, raw.valid_till,a.asset_id context_asset from table_changes('{system}',{last_commit_version}) raw left join ala2ass a on raw.alarm_type = a.alarm_type")
    
    max_commit_version = max_commit_version + 1
    # Update last_commit_version in table_commit_version for the data source table
    spark.sql(f"update table_commit_version set last_commit_version={max_commit_version} where table_name='{system}'")
    
    return df, df_tlb_change

# COMMAND ----------

df_alarm_master, df_tlb_change = process_data('tbl_alarm_master')

# COMMAND ----------

display(df_alarm_master)

# COMMAND ----------

display(df_tlb_change)

# COMMAND ----------

df_alarm_master.write \
               .format("jdbc") \
               .option("url", jdbc_url) \
               .option("dbtable", "Tbl_Alarm_Master") \
               .mode("append") \
               .save()
