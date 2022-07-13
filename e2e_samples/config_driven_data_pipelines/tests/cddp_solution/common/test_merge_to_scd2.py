from pyspark import SparkConf
from pyspark.sql import SparkSession
import datetime
from cddp_solution.common.utils.parquet_to_csv import parquet2csv
from cddp_solution.common.utils.merge_to_scd2 import merge_to_scd2
import tempfile
import io
import pandas as pd

from pandas.testing import assert_frame_equal


def test_merge_to_scd2():
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
FRUIT,COLOR,PRICE,key_hash
Peach,Yellow,3.0,53841c6e42a6ce77b6f3b80133c9342c
Green Apple,Green,2.5,6739c927851065a9d2c05edb191f9109
Orange,Orange,2.0,909cea0c97058cfe2e3ea8d675cb08e1
Banana,Yellow,1.0,e6f9c347672daae5a2557ae118f44a1e
Fiji Apple,Red,3.5,f3c73897c27b9dd4f112daee80f84bf3
Green Grape,Green,2.0,f4f4e87a9e2429e796c1facdff5db1d2
Red Grape,Red,2.0,f762658d6ef0697b845110ff46df36b1
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
FRUIT,COLOR,PRICE,key_hash
Yellow Apple,Yellow,2.5,32da933486eaf5ddbf2bda3f0fe3e4a6
Peach,Yellow,3.0,53841c6e42a6ce77b6f3b80133c9342c
Green Apple,Green,2.5,6739c927851065a9d2c05edb191f9109
Green Apple,Green,2.8,6739c927851065a9d2c05edb191f9109
Orange,Orange,2.0,909cea0c97058cfe2e3ea8d675cb08e1
Banana,Yellow,1.0,e6f9c347672daae5a2557ae118f44a1e
Fiji Apple,Red,3.5,f3c73897c27b9dd4f112daee80f84bf3
Green Grape,Green,2.0,f4f4e87a9e2429e796c1facdff5db1d2
Red Grape,Red,2.0,f762658d6ef0697b845110ff46df36b1
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
    scd2_df = merge_to_scd2(spark, raw_1, parquet_temp_dir, schema_name, partition_keys, key_cols, current_time)
    scd2_df.createOrReplaceTempView("fruits_1")
    panda_df = spark.sql("select FRUIT, COLOR, PRICE, key_hash from fruits_1 order by key_hash").toPandas()
    parquet2csv(parquet_temp_dir, csv_temp_dir+"/fruits-1.csv")
    raw_1.toPandas().to_csv(csv_temp_dir+"/fruits-raw.csv")
    panda_df.to_csv(csv_temp_dir+"/fruits-1-small.csv")

    data = io.StringIO(result_1)
    expected_df = pd.read_csv(data, sep=",")

    assert_frame_equal(panda_df, expected_df, check_dtype=False)

    current_time = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    scd2_df = merge_to_scd2(spark, raw_2, parquet_temp_dir, schema_name, partition_keys, key_cols, current_time)
    scd2_df.createOrReplaceTempView("fruits_2")
    panda_df = spark.sql("select FRUIT, COLOR, PRICE, key_hash \
                          from fruits_2 where Is_active='Y' order by key_hash, PRICE").toPandas()
    parquet2csv(parquet_temp_dir, csv_temp_dir+"/fruits-2.csv")
    panda_df.to_csv(csv_temp_dir+"/fruits-2-small.csv")

    data = io.StringIO(result_2)
    expected_df = pd.read_csv(data, sep=",")

    assert_frame_equal(panda_df, expected_df, check_dtype=False)

    # Test without saving ts_col and is_active_col
    # Test the first transformation
    scd2_df = merge_to_scd2(spark,
                            raw_2,
                            f"{parquet_temp_dir}_2",
                            schema_name,
                            partition_keys,
                            key_cols,
                            current_time,
                            save_to_ts_col=False,
                            save_is_active_col=False)
    assert scd2_df.columns == ['FRUIT', 'COLOR', 'PRICE', 'key_hash', 'row_active_start_ts']

    # Test target table already existed use case
    scd2_df = merge_to_scd2(spark,
                            raw_2,
                            f"{parquet_temp_dir}_2",
                            schema_name,
                            partition_keys,
                            key_cols,
                            current_time,
                            save_to_ts_col=False,
                            save_is_active_col=False)
    assert scd2_df.columns == ['row_active_start_ts', 'FRUIT', 'COLOR', 'PRICE', 'key_hash']
