from pyspark import SparkConf
from pyspark.sql import SparkSession
import datetime
from cddp_solution.common.utils.parquet_to_csv import parquet2csv
from cddp_solution.common.utils.scd2 import SCD2
import tempfile
import io
import pandas as pd

from pandas.testing import assert_frame_equal


def test_SCD2():
    spark = SparkSession.getActiveSession()
    if not spark:
        conf = SparkConf().setAppName("test-data-app").setMaster("local[*]")
        spark = SparkSession.builder.config(conf=conf)\
                            .config("spark.jars.packages",
                                    "io.delta:delta-core_2.12:1.2.0,\
                                     com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.21") \
                            .config("spark.driver.memory", "24G")\
                            .config("spark.driver.maxResultSize", "24G")\
                            .getOrCreate()

    schema_name = "scd2_test"
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")

    raw_1 = spark.createDataFrame([('Fiji Apple', 'Red', 3.5),
                                   ('Banana', 'Yellow', 1.0),
                                   ('Green Grape', 'Green', 2.0),
                                   ('Red Grape', 'Red', 2.0),
                                   ('Peach', 'Yellow', 3.0),
                                   ('Orange', 'Orange', 2.0),
                                   ('Green Apple', 'Green', 2.5)],
                                  ['Fruit', 'Color', 'Price'])

    result_1 = """
FRUIT,COLOR,PRICE,row_latest_ind,key_hash,data_hash
Peach,Yellow,3.0,Y,53841c6e42a6ce77b6f3b80133c9342c,577c11550a89d0d41b473a6103c03f68
Green Apple,Green,2.5,Y,6739c927851065a9d2c05edb191f9109,af120f44a5e66d0e8b07880709ba2c57
Orange,Orange,2.0,Y,909cea0c97058cfe2e3ea8d675cb08e1,a04b7044d3e7cb2f1c1e775eb569a0a3
Banana,Yellow,1.0,Y,e6f9c347672daae5a2557ae118f44a1e,df5c5b76a127715bd35a5bb93b482247
Fiji Apple,Red,3.5,Y,f3c73897c27b9dd4f112daee80f84bf3,82ac239d4ccf6603d373fe5a92df73d9
Green Grape,Green,2.0,Y,f4f4e87a9e2429e796c1facdff5db1d2,2725b5d2846ec3d6f79c254132719b4f
Red Grape,Red,2.0,Y,f762658d6ef0697b845110ff46df36b1,65e44fd552ae20dad64a8cf50b92067b
"""

    raw_2 = spark.createDataFrame([('Fiji Apple', 'Red', 3.5),
                                   ('Banana', 'Yellow', 1.0),
                                   ('Green Grape', 'Green', 2.0),
                                   ('Red Grape', 'Red', 2.0),
                                   ('Peach', 'Yellow', 3.0),
                                   ('Orange', 'Orange', 2.0),
                                   ('Green Apple', 'Green', 2.8),
                                   ('Yellow Apple', 'Yellow', 2.5)],
                                  ['Fruit', 'Color', 'Price'])

    result_2 = """
FRUIT,COLOR,PRICE,row_latest_ind,key_hash,data_hash
Green Apple,Green,2.5,N,6739c927851065a9d2c05edb191f9109,af120f44a5e66d0e8b07880709ba2c57
Yellow Apple,Yellow,2.5,Y,32da933486eaf5ddbf2bda3f0fe3e4a6,9cffca426edebdab03c0f701d9c81f49
Peach,Yellow,3.0,Y,53841c6e42a6ce77b6f3b80133c9342c,577c11550a89d0d41b473a6103c03f68
Green Apple,Green,2.8,Y,6739c927851065a9d2c05edb191f9109,3b651dbdb5c49db53a5df0b5fc6f27f9
Orange,Orange,2.0,Y,909cea0c97058cfe2e3ea8d675cb08e1,a04b7044d3e7cb2f1c1e775eb569a0a3
Banana,Yellow,1.0,Y,e6f9c347672daae5a2557ae118f44a1e,df5c5b76a127715bd35a5bb93b482247
Fiji Apple,Red,3.5,Y,f3c73897c27b9dd4f112daee80f84bf3,82ac239d4ccf6603d373fe5a92df73d9
Green Grape,Green,2.0,Y,f4f4e87a9e2429e796c1facdff5db1d2,2725b5d2846ec3d6f79c254132719b4f
Red Grape,Red,2.0,Y,f762658d6ef0697b845110ff46df36b1,65e44fd552ae20dad64a8cf50b92067b
"""
    parquet_temp_dir = str(tempfile.TemporaryDirectory().name)
    print(parquet_temp_dir)
    csv_temp_dir = str(tempfile.TemporaryDirectory().name)
    print(csv_temp_dir)

    # filepath = Path(csv_temp_dir)
    # filepath.mkdir(parents=True, exist_ok=True)

    # os.remove(parquet_temp_dir)
    # os.remove(csv_temp_dir)

    partition_keys = ""
    key_cols = "Fruit"
    current_time = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    scd2_df = SCD2(spark, raw_1, parquet_temp_dir, schema_name, partition_keys, key_cols, current_time)
    scd2_df.createOrReplaceTempView("fruits_1")
    panda_df = spark.sql("select FRUIT, COLOR, PRICE, row_latest_ind, key_hash, data_hash \
                          from fruits_1 order by row_latest_ind,key_hash,data_hash").toPandas()
    parquet2csv(parquet_temp_dir, csv_temp_dir+"/fruits-1.csv")
    raw_1.toPandas().to_csv(csv_temp_dir+"/fruits-raw.csv")
    panda_df.to_csv(csv_temp_dir+"/fruits-1-small.csv")

    data = io.StringIO(result_1)
    expected_df = pd.read_csv(data, sep=",")

    assert_frame_equal(panda_df, expected_df, check_dtype=False)

    current_time = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    scd2_df = SCD2(spark, raw_2, parquet_temp_dir, schema_name, partition_keys, key_cols, current_time)
    scd2_df.createOrReplaceTempView("fruits_2")
    panda_df = spark.sql("select FRUIT, COLOR, PRICE, row_latest_ind, key_hash, data_hash \
                          from fruits_2 order by row_latest_ind,key_hash,data_hash").toPandas()
    parquet2csv(parquet_temp_dir, csv_temp_dir+"/fruits-2.csv")
    panda_df.to_csv(csv_temp_dir+"/fruits-2-small.csv")

    data = io.StringIO(result_2)
    expected_df = pd.read_csv(data, sep=",")

    assert_frame_equal(panda_df, expected_df, check_dtype=False)
