#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `ddo_transform` package."""

import os
import sys
import pytest
import datetime
from pyspark.sql.functions import isnull

sys.path.append('../ddo_transform/')
from ddo_transform import standardize

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


def test_standardize_parking_bay(spark):
    """Test data transform"""
    # Arrange
    schema = standardize.get_schema("in_parkingbay_schema")
    parkingbay_sdf = spark.read.json("./data/MelbParkingBayData.json", multiLine=True, schema=schema)
    load_id = 1
    loaded_on = datetime.datetime.now()
    # Act
    t_parkingbay_sdf, t_parkingbay_malformed_sdf = standardize.standardize_parking_bay(parkingbay_sdf, load_id, loaded_on)  # noqa: E501
    # Assert
    assert t_parkingbay_sdf.count() != 0
    assert t_parkingbay_malformed_sdf.count() == 0
    assert t_parkingbay_sdf.filter(isnull("bay_id")).count() == 0


def test_standardize_sensordata(spark):
    """Test data transform"""
    # Arrange
    schema = standardize.get_schema("in_sensordata_schema")
    sensordata_sdf = spark.read.json("./data/MelbParkingSensorData.json", multiLine=True, schema=schema)
    load_id = 1
    loaded_on = datetime.datetime.now()
    # Act
    t_sensordata_sdf, t_sensordata_malformed_sdf = standardize.standardize_sensordata(sensordata_sdf, load_id, loaded_on)  # noqa: E501
    # Assert
    assert t_sensordata_sdf.count() != 0
    assert t_sensordata_malformed_sdf.count() == 0
    assert t_sensordata_sdf.filter(isnull("bay_id")).count() == 0
