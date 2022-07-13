from cddp_solution.common.utils.data_schema import AbstractDataSchema
from pyspark.sql.types import StructType, StructField, LongType, StringType, DoubleType


class DataSchema(AbstractDataSchema):
    def __init__(self, app_config):
        super().__init__(app_config)

    def get_schema(self):
        return StructType([
                StructField("ID", LongType()),
                StructField("shuiguo", StringType()),
                StructField("yanse", StringType()),
                StructField("jiage", DoubleType())
            ])
