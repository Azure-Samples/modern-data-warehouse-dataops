#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `ddo_transform` package."""
import datetime
import os

import libraries.src.ddo_transform_standardize as standardize
import pytest
from pyspark.sql import SparkSession
from pyspark.sql.functions import isnull
from pyspark.sql.types import (
    ArrayType,
    DoubleType,
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)

load_id = "00000000-0000-0000-0000-000000000000"
loaded_on = datetime.datetime.now()
data_path = os.path.join(os.path.dirname(__file__), "data/")


@pytest.fixture
def spark() -> SparkSession:
    """Spark Session fixture"""
    spark = SparkSession.builder.master("local[2]").appName("Unit Testing").getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    return spark


def expected_parkingbay_schema(bay_id_nullable: bool = False) -> StructType:
    """Create the expected schema for the parking bay data"""
    expected_schema_parkingbay = StructType(
        [
            StructField("bay_id", IntegerType(), bay_id_nullable),
            StructField("last_edit", TimestampType()),
            StructField("marker_id", StringType()),
            StructField("meter_id", StringType()),
            StructField("rd_seg_dsc", StringType()),
            StructField("rd_seg_id", IntegerType()),
            StructField(
                "the_geom",
                StructType(
                    [
                        StructField("coordinates", ArrayType(ArrayType(ArrayType(ArrayType(DoubleType()))))),
                        StructField("type", StringType()),
                    ]
                ),
            ),
            StructField("load_id", StringType(), False),
            StructField("loaded_on", TimestampType()),
        ]
    )
    return expected_schema_parkingbay


def expected_sensordata_schema(bay_id_nullable: bool = False) -> StructType:
    """Create the expected schema for the sensor data"""
    expected_schema_sensordata = StructType(
        [
            StructField("bay_id", IntegerType(), bay_id_nullable),
            StructField("st_marker_id", StringType()),
            StructField("lat", FloatType()),
            StructField("lon", FloatType()),
            StructField(
                "location",
                StructType([StructField("coordinates", ArrayType(DoubleType())), StructField("type", StringType())]),
            ),
            StructField("status", StringType()),
            StructField("load_id", StringType(), False),
            StructField("loaded_on", TimestampType()),
        ]
    )
    return expected_schema_sensordata


def test_standardize_parking_bay(spark: SparkSession) -> None:
    """Test data standardization"""
    # Arrange
    schema = standardize.get_schema("in_parkingbay_schema")
    parkingbay_sdf = spark.read.json(os.path.join(data_path, "MelbParkingBayData.json"), multiLine=True, schema=schema)

    # Act
    t_parkingbay_sdf, t_parkingbay_malformed_sdf = standardize.standardize_parking_bay(
        parkingbay_sdf, load_id, loaded_on
    )  # noqa: E501

    # Assert
    assert t_parkingbay_sdf.count() != 0
    assert t_parkingbay_malformed_sdf.count() == 1
    assert t_parkingbay_sdf.filter(isnull("bay_id")).count() == 0

    # Ensure that each bay_id occurs only once
    assert t_parkingbay_sdf.groupBy("bay_id").count().filter("count > 1").count() == 0

    # Ensure that the schema is as expected
    assert t_parkingbay_sdf.schema.simpleString() == expected_parkingbay_schema().simpleString()
    assert t_parkingbay_malformed_sdf.schema.simpleString() == expected_parkingbay_schema(True).simpleString()


def test_standardize_sensordata(spark: SparkSession) -> None:
    """Test data standardization"""
    # Arrange
    schema = standardize.get_schema("in_sensordata_schema")
    sensordata_sdf = spark.read.json(
        os.path.join(data_path, "MelbParkingSensorData.json"), multiLine=True, schema=schema
    )

    # Act
    t_sensordata_sdf, t_sensordata_malformed_sdf = standardize.standardize_sensordata(
        sensordata_sdf, load_id, loaded_on
    )  # noqa: E501

    # Assert
    assert t_sensordata_sdf.count() != 0
    assert t_sensordata_malformed_sdf.count() == 1
    assert t_sensordata_sdf.filter(isnull("bay_id")).count() == 0

    # Ensure that the schema is as expected
    assert t_sensordata_sdf.schema.simpleString() == expected_sensordata_schema().simpleString()
    assert t_sensordata_malformed_sdf.schema.simpleString() == expected_sensordata_schema(True).simpleString()
