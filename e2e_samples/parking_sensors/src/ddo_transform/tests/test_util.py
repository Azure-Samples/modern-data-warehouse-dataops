#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `ddo_transform` package."""

import os
import sys
import pytest
from delta import DeltaTable
from pyspark.sql import DataFrame


sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from ddo_transform import util


@pytest.fixture
def spark():
    """Spark Session fixture
    """
    from pyspark.sql import SparkSession

    spark = SparkSession.builder\
        .master("local[2]")\
        .appName("Unit Testing")\
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")\
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")\
        .getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    return spark


def test_append_delta(spark, tmp_path):
    from pyspark.sql.types import (StructType, StructField, StringType, LongType, TimestampType, ArrayType)
    table = "mytable"

    schema = StructType([
        StructField('name', StringType(), False),
        StructField('age', LongType(), False),
    ])
    initialize_delta_table(spark, table, str(tmp_path), schema, [['Alice', 1], ['Bob', 2]])

    df = spark.createDataFrame(data=[['Alice', 3], ['Charlie', 4]], schema=schema)

    util.append_delta(spark, df, table)

    actual = DeltaTable.forPath(spark, str(tmp_path)).toDF()
    expected = spark.createDataFrame(data=[['Alice', 1], ['Bob', 2], ['Alice', 3], ['Charlie', 4]], schema=schema)

    assert_data_frame_equals(expected, actual)


def initialize_delta_table(spark, table, path, schema, initial_data=[]) -> DeltaTable:
    (spark.createDataFrame(data=initial_data, schema=schema).write
        .format("delta")
        .mode("overwrite")
        .saveAsTable(table, path=path))

def assert_data_frame_equals(expected: DataFrame, actual: DataFrame):
    assert set(expected.columns) == set(actual.columns)
    assert (actual.select(expected.columns).orderBy(actual.columns).collect() ==
            expected.select(expected.columns).orderBy(actual.columns).collect())
