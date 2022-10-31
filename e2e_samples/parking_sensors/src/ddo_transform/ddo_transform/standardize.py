# -*- coding: utf-8 -*-

"""Main module."""


from pyspark.sql import DataFrame
from pyspark.sql.functions import lit, col, to_timestamp
from pyspark.sql.types import (
    ArrayType, StructType, StructField, StringType, DoubleType)  # noqa: E501


def get_schema(schema_name):
    if schema_name == 'in_parkingbay_schema':
        schema = StructType([
            StructField('the_geom', StructType([
                StructField('coordinates', ArrayType(
                    ArrayType(ArrayType(ArrayType(DoubleType())))
                )),
                StructField('type', StringType())
            ])),
            StructField('marker_id', StringType()),
            StructField('meter_id', StringType()),
            StructField('bay_id', StringType(), False),
            StructField('last_edit', StringType()),
            StructField('rd_seg_id', StringType()),
            StructField('rd_seg_dsc', StringType()),
        ])
    elif schema_name == 'in_sensordata_schema':
        schema = StructType([
            StructField('bay_id', StringType(), False),
            StructField('st_marker_id', StringType()),
            StructField('status', StringType()),
            StructField('location', StructType([
                StructField('coordinates', ArrayType(DoubleType())),
                StructField('type', StringType())
            ])),
            StructField('lat', StringType()),
            StructField('lon', StringType())
        ])
    return schema


def standardize_parking_bay(parkingbay_sdf: DataFrame, load_id, loaded_on):
    t_parkingbay_sdf = (
        parkingbay_sdf
        .drop_duplicates(["bay_id"])
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
            lit(loaded_on.isoformat()).cast("timestamp").alias("loaded_on")
        )
    ).cache()
    # Data Validation
    good_records = t_parkingbay_sdf.filter(col("bay_id").isNotNull())
    bad_records = t_parkingbay_sdf.filter(col("bay_id").isNull())
    return good_records, bad_records


def standardize_sensordata(sensordata_sdf: DataFrame, load_id, loaded_on):
    t_sensordata_sdf = (
        sensordata_sdf
        .select(
            col("bay_id").cast("int").alias("bay_id"),
            "st_marker_id",
            col("lat").cast("float").alias("lat"),
            col("lon").cast("float").alias("lon"),
            "location",
            "status",
            lit(load_id).alias("load_id"),
            lit(loaded_on.isoformat()).cast("timestamp").alias("loaded_on")
        )
    ).cache()
    # Data Validation
    good_records = t_sensordata_sdf.filter(col("bay_id").isNotNull())
    bad_records = t_sensordata_sdf.filter(col("bay_id").isNull())
    return good_records, bad_records


if __name__ == "__main__":
    from pyspark.sql import SparkSession
    import datetime
    import os

    spark = SparkSession.builder\
        .master("local[2]")\
        .appName("standardize.py")\
        .getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")

    THIS_DIR = os.path.dirname(os.path.abspath(__file__))

    schema = get_schema("in_parkingbay_schema")
    parkingbay_sdf = spark.read.json(os.path.join(THIS_DIR, "../data/MelbParkingBayData.json"),
                                     multiLine=True,
                                     schema=schema)
    load_id = 1
    loaded_on = datetime.datetime.now()
    t_parkingbay_sdf, t_parkingbay_malformed_sdf = standardize_parking_bay(parkingbay_sdf, load_id, loaded_on)
    t_parkingbay_sdf.write.json('./out/parkingbay_sdf')
