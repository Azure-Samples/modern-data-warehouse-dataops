from cddp_solution.common.event_data_transformation import AbstractEventDataTransformation
from pyspark.sql.types import *

class EventDataTransformation(AbstractEventDataTransformation):
    def __init__(self, config):
        super().__init__(config)

    def get_default_event_schema(self):
        return StructType([
                StructField("id", LongType()),
                StructField("amount", LongType()),
                StructField("ts", TimestampType())
            ])
    