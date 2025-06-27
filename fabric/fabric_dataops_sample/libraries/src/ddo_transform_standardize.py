# -*- coding: utf-8 -*-

"""Main module."""


from typing import Tuple

from pyspark.sql import DataFrame
from pyspark.sql.functions import col, lit, to_timestamp
from pyspark.sql.types import ArrayType, DoubleType, StringType, StructField, StructType, TimestampType  # noqa: E501


def get_schema(schema_name: StringType) -> StructType:
    if schema_name == "in_parkingbay_schema":
        schema = StructType(
            [
                StructField(
                    "the_geom",
                    StructType(
                        [
                            StructField("coordinates", ArrayType(ArrayType(ArrayType(ArrayType(DoubleType()))))),
                            StructField("type", StringType()),
                        ]
                    ),
                ),
                StructField("marker_id", StringType()),
                StructField("meter_id", StringType()),
                StructField("bay_id", StringType(), False),
                StructField("last_edit", StringType()),
                StructField("rd_seg_id", StringType()),
                StructField("rd_seg_dsc", StringType()),
            ]
        )
    elif schema_name == "in_sensordata_schema":
        schema = StructType(
            [
                StructField("bay_id", StringType(), False),
                StructField("st_marker_id", StringType()),
                StructField("status", StringType()),
                StructField(
                    "location",
                    StructType(
                        [StructField("coordinates", ArrayType(DoubleType())), StructField("type", StringType())]
                    ),
                ),
                StructField("lat", StringType()),
                StructField("lon", StringType()),
            ]
        )
    return schema


def standardize_parking_bay(
    parkingbay_sdf: DataFrame, load_id: StringType, loaded_on: TimestampType
) -> Tuple[DataFrame, DataFrame]:
    t_parkingbay_sdf = (
        parkingbay_sdf.drop_duplicates(["bay_id"])
        .withColumn("last_edit", to_timestamp("last_edit", "yyyyMMddHHmmss"))
        .select(
            col("bay_id").cast("int").alias("bay_id"),
            "last_edit",
            "marker_id",
            "meter_id",
            "rd_seg_dsc",
            col("rd_seg_id").cast("int").alias("rd_seg_id"),
            "the_geom",
            lit(load_id).alias("load_id"),
            lit(loaded_on.isoformat()).cast("timestamp").alias("loaded_on"),
        )
    ).cache()
    # Data Validation
    good_records = t_parkingbay_sdf.filter(col("bay_id").isNotNull())
    bad_records = t_parkingbay_sdf.filter(col("bay_id").isNull())
    return good_records, bad_records


def standardize_sensordata(
    sensordata_sdf: DataFrame, load_id: StringType, loaded_on: TimestampType
) -> Tuple[DataFrame, DataFrame]:
    t_sensordata_sdf = (
        sensordata_sdf.select(
            col("bay_id").cast("int").alias("bay_id"),
            "st_marker_id",
            col("lat").cast("float").alias("lat"),
            col("lon").cast("float").alias("lon"),
            "location",
            "status",
            lit(load_id).alias("load_id"),
            lit(loaded_on.isoformat()).cast("timestamp").alias("loaded_on"),
        )
    ).cache()
    # Data Validation
    good_records = t_sensordata_sdf.filter(col("bay_id").isNotNull())
    bad_records = t_sensordata_sdf.filter(col("bay_id").isNull())
    return good_records, bad_records
