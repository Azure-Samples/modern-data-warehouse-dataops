import unittest

import pandas as pd
from pyspark.sql import Row, SparkSession
from pyspark.sql.dataframe import DataFrame

from modules.pump_utils import get_litres_per_second


class TestGetLitresPerSecond(unittest.TestCase):
    def setUp(self):
        self.spark = SparkSession.builder.getOrCreate()

    def test_get_litres_per_second(self):
        test_data = [
            # pipe_id, start_time, end_time, litres_pumped
            (1, '2021-02-01 01:05:32', '2021-02-01 01:09:13', 24),
            (2, '2021-02-01 01:09:14', '2021-02-01 01:14:17', 41),
            (1, '2021-02-01 01:14:18', '2021-02-01 01:15:58', 11),
            (2, '2021-02-01 01:15:59', '2021-02-01 01:18:26', 13),
            (1, '2021-02-01 01:18:27', '2021-02-01 01:26:26', 45),
            (3, '2021-02-01 01:26:27', '2021-02-01 01:38:57', 15)
        ]
        test_data = [
            {
                'pipe_id': row[0],
                'start_time': row[1],
                'end_time': row[2],
                'litres_pumped': row[3]
            } for row in test_data
        ]
        test_df = self.spark.createDataFrame(map(lambda x: Row(**x), test_data))
        output_df = get_litres_per_second(test_df)

        self.assertIsInstance(output_df, DataFrame)

        output_df_as_pd = output_df.sort('pipe_id').toPandas()

        expected_output_df = pd.DataFrame([
            {
                'pipe_id': 1,
                'total_duration_seconds': 800,
                'total_litres_pumped': 80,
                'avg_litres_per_second': 0.1
            },
            {
                'pipe_id': 2,
                'total_duration_seconds': 450,
                'total_litres_pumped': 54,
                'avg_litres_per_second': 0.12
            },
            {
                'pipe_id': 3,
                'total_duration_seconds': 750,
                'total_litres_pumped': 15,
                'avg_litres_per_second': 0.02
            },
        ])
        pd.testing.assert_frame_equal(expected_output_df, output_df_as_pd)
