# -*- coding: utf-8 -*-

"""Main module."""


import uuid

from pyspark.sql import DataFrame
from pyspark.sql.functions import col, lit, udf, when
from pyspark.sql.types import (  # noqa: E501
    ArrayType,
    DoubleType,
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
    TimestampType,
)

uuidUdf = udf(lambda: str(uuid.uuid4()), StringType())
EMPTY_UUID = "00000000-0000-0000-0000-000000000000"


def get_schema(schema_name: StringType) -> StructType:
    schema = None
    if schema_name == "interim_parkingbay_schema":
        schema = StructType(
            [
                StructField("bay_id", IntegerType(), False),
                StructField("last_edit", StringType()),
                StructField("marker_id", StringType()),
                StructField("meter_id", StringType()),
                StructField("rd_seg_id", IntegerType()),
                StructField("rd_seg_dsc", StringType()),
                StructField(
                    "the_geom",
                    StructType(
                        [
                            StructField("coordinates", ArrayType(ArrayType(ArrayType(ArrayType(DoubleType()))))),
                            StructField("type", StringType()),
                        ]
                    ),
                ),
                StructField("load_id", StringType()),
                StructField("loaded_on", TimestampType()),
            ]
        )
    elif schema_name == "interim_sensor":
        schema = StructType(
            [
                StructField("bay_id", IntegerType(), False),
                StructField("st_marker_id", StringType()),
                StructField("lat", FloatType()),
                StructField("lon", FloatType()),
                StructField(
                    "location",
                    StructType(
                        [StructField("coordinates", ArrayType(DoubleType())), StructField("type", StringType())]
                    ),
                    False,
                ),
                StructField("status", StringType()),
                StructField("load_id", StringType()),
                StructField("loaded_on", TimestampType()),
            ]
        )
    elif schema_name == "dw_dim_parking_bay":
        schema = StructType(
            [
                StructField("dim_parking_bay_id", StringType(), False),
                StructField("bay_id", IntegerType(), False),
                StructField("marker_id", StringType()),
                StructField("meter_id", StringType()),
                StructField("rd_seg_id", IntegerType()),
                StructField("rd_seg_dsc", StringType()),
                StructField(
                    "the_geom",
                    StructType(
                        [
                            StructField("coordinates", ArrayType(ArrayType(ArrayType(ArrayType(DoubleType()))))),
                            StructField("type", StringType()),
                        ]
                    ),
                ),
                StructField("load_id", StringType()),
                StructField("loaded_on", TimestampType()),
            ]
        )
    elif schema_name == "dw_dim_location":
        schema = StructType(
            [
                StructField("dim_location_id", StringType(), False),
                StructField(
                    "location",
                    StructType(
                        [StructField("coordinates", ArrayType(DoubleType())), StructField("type", StringType())]
                    ),
                    False,
                ),
                StructField("lat", FloatType()),
                StructField("lon", FloatType()),
                StructField("load_id", StringType()),
                StructField("loaded_on", TimestampType()),
            ]
        )
    elif schema_name == "dw_dim_st_marker":
        schema = StructType(
            [
                StructField("dim_st_marker_id", StringType(), False),
                StructField("st_marker_id", StringType()),
                StructField("load_id", StringType()),
                StructField("loaded_on", TimestampType()),
            ]
        )
    return schema


def process_dim_parking_bay(
    parkingbay_sdf: DataFrame, dim_parkingbay_sdf: DataFrame, load_id: StringType, loaded_on: TimestampType
) -> DataFrame:
    """Transform incoming parkingbay_sdf data and existing dim_parking_bay
    into the latest version of records of dim_parking_bay data.
    """
    # Get landing data distinct rows
    parkingbay_sdf = parkingbay_sdf.select(["bay_id", "marker_id", "meter_id", "rd_seg_dsc", "rd_seg_id"]).distinct()

    # Using a left_outer join on the business key (bay_id),
    # identify rows that do NOT EXIST in landing data that EXISTS in existing Dimension table
    oldrows_parkingbay_sdf = (
        dim_parkingbay_sdf.alias("dim")
        .join(parkingbay_sdf, "bay_id", "left_outer")
        .where(parkingbay_sdf["bay_id"].isNull())
        .select(col("dim.*"))
    )

    # Using a left_outer join on the business key (bay_id),
    # Identify rows that EXISTS in incoming landing data that does also EXISTS in existing Dimension table
    # and take the values of the incoming landing data. That is, we update existing table values.
    existingrows_parkingbay_sdf = (
        parkingbay_sdf.alias("pb")
        .join(dim_parkingbay_sdf.alias("dim"), "bay_id", "left_outer")
        .where(dim_parkingbay_sdf["bay_id"].isNotNull())
        .select(
            col("dim.dim_parking_bay_id"),
            col("pb.bay_id"),
            col("pb.marker_id"),
            col("pb.meter_id"),
            col("pb.rd_seg_dsc"),
            col("pb.rd_seg_id"),
        )
    )

    # Using a left_outer join on the business key (bay_id),
    # Identify rows that EXISTS in landing data that does NOT EXISTS in existing Dimension table
    newrows_parkingbay_sdf = (
        parkingbay_sdf.alias("pb")
        .join(dim_parkingbay_sdf, "bay_id", "left_outer")
        .where(dim_parkingbay_sdf["bay_id"].isNull())
        .select(col("pb.*"))
    )

    # Add load_id, loaded_at and dim_parking_bay_id
    existingrows_parkingbay_sdf = existingrows_parkingbay_sdf.withColumn("load_id", lit(load_id)).withColumn(
        "loaded_on", lit(loaded_on.isoformat()).cast("timestamp")
    )
    newrows_parkingbay_sdf = (
        newrows_parkingbay_sdf.withColumn("load_id", lit(load_id))
        .withColumn("loaded_on", lit(loaded_on.isoformat()).cast("timestamp"))
        .withColumn("dim_parking_bay_id", uuidUdf())
    )

    # Select relevant columns
    relevant_cols = [
        "dim_parking_bay_id",
        "bay_id",
        "marker_id",
        "meter_id",
        "rd_seg_dsc",
        "rd_seg_id",
        "load_id",
        "loaded_on",
    ]
    oldrows_parkingbay_sdf = oldrows_parkingbay_sdf.select(relevant_cols)
    existingrows_parkingbay_sdf = existingrows_parkingbay_sdf.select(relevant_cols)
    newrows_parkingbay_sdf = newrows_parkingbay_sdf.select(relevant_cols)

    allrows_parkingbay_sdf = oldrows_parkingbay_sdf.union(existingrows_parkingbay_sdf).union(newrows_parkingbay_sdf)

    return allrows_parkingbay_sdf


def process_dim_location(
    sensordata_sdf: DataFrame, dim_location: DataFrame, load_id: StringType, loaded_on: TimestampType
) -> DataFrame:
    """Transform sensordata into dim_location"""

    # Get landing data distint rows
    sensordata_sdf = sensordata_sdf.select(["lat", "lon"]).distinct()

    # Using a left_outer join
    # identify rows that do NOT EXIST in landing data that EXISTS in existing Dimension table
    oldrows_sdf = (
        dim_location.alias("dim")
        .join(sensordata_sdf, ["lat", "lon"], "left_outer")
        .where(sensordata_sdf["lat"].isNull() & sensordata_sdf["lon"].isNull())
        .select(col("dim.*"))
    )

    # Using a left_outer join
    # Identify rows that EXISTS in incoming landing data that does also EXISTS in existing Dimension table
    # and take the values of the incoming landing data. That is, we update existing table values.
    existingrows_sdf = (
        sensordata_sdf.alias("in")
        .join(dim_location.alias("dim"), ["lat", "lon"], "left_outer")
        .where(dim_location["lat"].isNotNull() & dim_location["lon"].isNotNull())
        .select(col("dim.dim_location_id"), col("in.lat"), col("in.lon"))
    )

    # Using a left_outer join
    # Identify rows that EXISTS in landing data that does NOT EXISTS in existing Dimension table
    newrows_sdf = (
        sensordata_sdf.alias("in")
        .join(dim_location, ["lat", "lon"], "left_outer")
        .where(dim_location["lat"].isNull() & dim_location["lon"].isNull())
        .select(col("in.*"))
    )

    # Add load_id, loaded_at and dim_parking_bay_id
    existingrows_sdf = existingrows_sdf.withColumn("load_id", lit(load_id)).withColumn(
        "loaded_on", lit(loaded_on.isoformat()).cast("timestamp")
    )
    newrows_sdf = (
        newrows_sdf.withColumn("load_id", lit(load_id))
        .withColumn("loaded_on", lit(loaded_on.isoformat()).cast("timestamp"))
        .withColumn("dim_location_id", uuidUdf())
    )

    # Select relevant columns
    relevant_cols = ["dim_location_id", "lat", "lon", "load_id", "loaded_on"]
    oldrows_sdf = oldrows_sdf.select(relevant_cols)
    existingrows_sdf = existingrows_sdf.select(relevant_cols)
    newrows_sdf = newrows_sdf.select(relevant_cols)

    allrows_sdf = oldrows_sdf.union(existingrows_sdf).union(newrows_sdf)

    return allrows_sdf


def process_dim_st_marker(
    sensordata_sdf: DataFrame, dim_st_marker: DataFrame, load_id: StringType, loaded_on: TimestampType
) -> DataFrame:
    """Transform sensordata into dim_st_marker"""

    # Get landing data distint rows
    sensordata_sdf = sensordata_sdf.select(["st_marker_id"]).distinct()

    # Using a left_outer join
    # identify rows that do NOT EXIST in landing data that EXISTS in existing Dimension table
    oldrows_sdf = (
        dim_st_marker.alias("dim")
        .join(sensordata_sdf, ["st_marker_id"], "left_outer")
        .where(sensordata_sdf["st_marker_id"].isNull())
        .select(col("dim.*"))
    )

    # Using a left_outer join
    # Identify rows that EXISTS in incoming landing data that does also EXISTS in existing Dimension table
    # and take the values of the incoming landing data. That is, we update existing table values.
    existingrows_sdf = (
        sensordata_sdf.alias("in")
        .join(dim_st_marker.alias("dim"), ["st_marker_id"], "left_outer")
        .where(dim_st_marker["st_marker_id"].isNotNull())
        .select(col("dim.dim_st_marker_id"), col("in.st_marker_id"))
    )

    # Using a left_outer join
    # Identify rows that EXISTS in landing data that does NOT EXISTS in existing Dimension table
    newrows_sdf = (
        sensordata_sdf.alias("in")
        .join(dim_st_marker, ["st_marker_id"], "left_outer")
        .where(dim_st_marker["st_marker_id"].isNull())
        .select(col("in.*"))
    )

    # Add load_id, loaded_at and dim_parking_bay_id
    existingrows_sdf = existingrows_sdf.withColumn("load_id", lit(load_id)).withColumn(
        "loaded_on", lit(loaded_on.isoformat()).cast("timestamp")
    )
    newrows_sdf = (
        newrows_sdf.withColumn("load_id", lit(load_id))
        .withColumn("loaded_on", lit(loaded_on.isoformat()).cast("timestamp"))
        .withColumn("dim_st_marker_id", uuidUdf())
    )

    # Select relevant columns
    relevant_cols = ["dim_st_marker_id", "st_marker_id", "load_id", "loaded_on"]
    oldrows_sdf = oldrows_sdf.select(relevant_cols)
    existingrows_sdf = existingrows_sdf.select(relevant_cols)
    newrows_sdf = newrows_sdf.select(relevant_cols)

    allrows_sdf = oldrows_sdf.union(existingrows_sdf).union(newrows_sdf)

    return allrows_sdf


def process_fact_parking(
    sensordata_sdf: DataFrame,
    dim_parkingbay_sdf: DataFrame,
    dim_location_sdf: DataFrame,
    dim_st_marker_sdf: DataFrame,
    load_id: StringType,
    loaded_on: TimestampType,
) -> DataFrame:
    """Transform sensordata into fact_parking"""

    dim_date_id = loaded_on.strftime("%Y%m%d")
    midnight = loaded_on.replace(hour=0, minute=0, second=0, microsecond=0)
    dim_time_id = (midnight - loaded_on).seconds

    # Build fact
    fact_parking = (
        sensordata_sdf.join(dim_parkingbay_sdf.alias("pb"), "bay_id", "left_outer")
        .join(dim_location_sdf.alias("l"), ["lat", "lon"], "left_outer")
        .join(dim_st_marker_sdf.alias("st"), "st_marker_id", "left_outer")
        .select(
            lit(dim_date_id).alias("dim_date_id"),
            lit(dim_time_id).alias("dim_time_id"),
            when(col("pb.dim_parking_bay_id").isNull(), lit(EMPTY_UUID))
            .otherwise(col("pb.dim_parking_bay_id"))
            .alias("dim_parking_bay_id"),
            when(col("l.dim_location_id").isNull(), lit(EMPTY_UUID))
            .otherwise(col("l.dim_location_id"))
            .alias("dim_location_id"),
            when(col("st.dim_st_marker_id").isNull(), lit(EMPTY_UUID))
            .otherwise(col("st.dim_st_marker_id"))
            .alias("dim_st_marker_id"),
            "status",
            lit(load_id).alias("load_id"),
            lit(loaded_on.isoformat()).cast("timestamp").alias("loaded_on"),
        )
    )
    return fact_parking
