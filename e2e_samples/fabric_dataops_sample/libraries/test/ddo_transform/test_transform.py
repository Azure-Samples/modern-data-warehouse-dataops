#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `ddo_transform` package."""
import datetime
import os

import libraries.src.ddo_transform_transform as transform
import pytest
from pyspark.sql import SparkSession
from pyspark.sql.functions import isnull
from pyspark.sql.types import IntegerType, StringType, StructField, StructType, TimestampType

load_id = "00000000-0000-0000-0000-000000000000"
loaded_on = datetime.datetime.now()
data_path = os.path.join(os.path.dirname(__file__), "data/")


@pytest.fixture
def spark() -> SparkSession:
    """Spark Session fixture"""
    spark = SparkSession.builder.master("local[2]").appName("Unit Testing").getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    return spark


def expected_process_dim_parking_bay_schema() -> StructType:
    """Create the expected schema for the dim parking bay data"""
    expected_schema_process_dim_parking_bay = StructType(
        [
            StructField("dim_parking_bay_id", StringType(), False),
            StructField("bay_id", IntegerType(), False),
            StructField("marker_id", StringType()),
            StructField("meter_id", StringType()),
            StructField("rd_seg_dsc", StringType()),
            StructField("rd_seg_id", IntegerType()),
            StructField("load_id", StringType(), False),
            StructField("loaded_on", TimestampType()),
        ]
    )
    return expected_schema_process_dim_parking_bay


def expected_process_fact_parking_schema() -> StructType:
    """Create the expected schema for the fact parking data"""
    expected_process_fact_parking = StructType(
        [
            StructField("dim_date_id", StringType()),
            StructField("dim_time_id", IntegerType()),
            StructField("dim_parking_bay_id", StringType(), False),
            StructField("dim_location_id", StringType(), False),
            StructField("dim_st_marker_id", StringType(), False),
            StructField("status", StringType()),
            StructField("load_id", StringType(), False),
            StructField("loaded_on", TimestampType()),
        ]
    )
    return expected_process_fact_parking


def test_process_dim_parking_bay(spark: SparkSession) -> None:
    """Test data transform"""
    # Arrange
    parkingbay_sdf = spark.read.json(
        os.path.join(data_path, "interim_parking_bay.json"),
        multiLine=True,
        schema=transform.get_schema("interim_parkingbay_schema"),
    )
    dim_parkingbay_sdf = spark.read.json(
        os.path.join(data_path, "dim_parking_bay.json"),
        multiLine=True,
        schema=transform.get_schema("dw_dim_parking_bay"),
    )
    # Filter out the data from each DataFrame to ensure that the act function is working as expected
    parkingbay_sdf = parkingbay_sdf.filter((parkingbay_sdf.bay_id != 3787) & (parkingbay_sdf.bay_id != 4318))
    dim_parkingbay_sdf = dim_parkingbay_sdf.filter(dim_parkingbay_sdf.bay_id != 21016)

    # Act
    results_df = transform.process_dim_parking_bay(parkingbay_sdf, dim_parkingbay_sdf, load_id, loaded_on)

    # Assert
    assert results_df.count() == 998
    assert results_df.filter(results_df.bay_id == 3787).count() == 1
    assert results_df.filter(results_df.bay_id == 4318).count() == 1
    assert results_df.filter(results_df.bay_id == 21016).count() == 1
    assert results_df.filter(isnull("dim_parking_bay_id")).count() == 0

    # Ensure that the schema is as expected
    assert results_df.schema.simpleString() == expected_process_dim_parking_bay_schema().simpleString()


def test_process_fact_parking(spark: SparkSession) -> None:
    """Test data transform"""
    # Arrange
    sensor_sdf = spark.read.json(
        os.path.join(data_path, "interim_sensor.json"), multiLine=True, schema=transform.get_schema("interim_sensor")
    )
    dim_parking_bay_sdf = spark.read.json(
        os.path.join(data_path, "dim_parking_bay.json"),
        multiLine=True,
        schema=transform.get_schema("dw_dim_parking_bay"),
    )
    dim_location_sdf = spark.read.json(
        os.path.join(data_path, "dim_location.json"), multiLine=True, schema=transform.get_schema("dw_dim_location")
    )
    dim_st_marker_sdf = spark.read.json(
        os.path.join(data_path, "dim_st_marker.json"), multiLine=True, schema=transform.get_schema("dw_dim_st_marker")
    )

    # Act
    results_df = transform.process_fact_parking(
        sensor_sdf, dim_parking_bay_sdf, dim_location_sdf, dim_st_marker_sdf, load_id, loaded_on
    )

    # Assert
    assert results_df.count() != 0
    assert results_df.filter(isnull("dim_parking_bay_id")).count() == 0

    # Ensure that the schema is as expected
    assert results_df.schema.simpleString() == expected_process_fact_parking_schema().simpleString()
