#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `ddo_transform` package."""

import os
import sys
import pytest
import datetime

sys.path.append('../ddo_transform/')
from ddo_transform import transform

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


@pytest.fixture
def spark():
    """Spark Session fixture
    """
    from pyspark.sql import SparkSession

    spark = SparkSession.builder\
        .master("local[2]")\
        .appName("Unit Testing")\
        .getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    return spark


def test_process_dim_parking_bay(spark):
    """Test data transform"""
    parkingbay_sdf = spark.read\
        .schema(transform.get_schema("interim_parkingbay_schema"))\
        .json(os.path.join(THIS_DIR, "../data/interim_parking_bay.json"))
    dim_parkingbay_sdf = spark.read\
        .schema(schema=transform.get_schema("dw_dim_parking_bay"))\
        .json(os.path.join(THIS_DIR, "../data/dim_parking_bay.json"))

    load_id = 1
    loaded_on = datetime.datetime.now()
    results_df = transform.process_dim_parking_bay(parkingbay_sdf, dim_parkingbay_sdf, load_id, loaded_on)

    # TODO add more asserts
    assert results_df.count() != 0
