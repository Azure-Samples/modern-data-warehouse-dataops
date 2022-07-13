from pyspark import SparkConf
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, LongType
from cddp_solution.common.utils.CddpException import CddpException
from cddp_solution.common.utils.schema_compare import validate_schema
import pytest


def test_schema_compare():
    spark = SparkSession.getActiveSession()
    if not spark:
        conf = SparkConf().setAppName("data-app").setMaster("local[*]")
        spark = SparkSession.builder.config(conf=conf)\
            .getOrCreate()

    df = spark.createDataFrame([('Fiji Apple', 'Red', 3.5),
                                ('Banana', 'Yellow', 1.0),
                                ('Green Grape', 'Green', 2.0),
                                ('Red Grape', 'Red', 2.0),
                                ('Peach', 'Yellow', 3.0),
                                ('Orange', 'Orange', 2.0),
                                ('Green Apple', 'Green', 2.5)],
                               ['Fruit', 'Color', 'Price'])

    schema = StructType([
                StructField("Fruit", StringType()),
                StructField("Color", StringType()),
                StructField("Price", DoubleType())
            ])
    res = validate_schema(schema, df)
    assert res

    # Test schema not match use case
    schema = StructType([
                StructField("Fruit", LongType()),
                StructField("Color", StringType()),
                StructField("Price", DoubleType())
            ])

    with pytest.raises(CddpException) as e:
        validate_schema(schema, df)
    assert str(e.value) == ("[CddpException|SchemaNotEqualError] Column Fruit LongType True not found!")
