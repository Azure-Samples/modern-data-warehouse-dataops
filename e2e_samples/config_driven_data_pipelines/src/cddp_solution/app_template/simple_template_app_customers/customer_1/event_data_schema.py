from cddp_solution.common.utils.data_schema import AbstractDataSchema
from pyspark.sql.types import *

class DataSchema(AbstractDataSchema):
    def __init__(self, app_config):
        super().__init__(app_config)
        
    def get_schema(self): 
        return StructType([
                StructField("ID", LongType()),
                StructField("amount", LongType()),
                StructField("ts", TimestampType())
            ])
        
