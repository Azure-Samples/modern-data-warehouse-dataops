import unittest

import pandas as pd
from pyspark.sql import Row, SparkSession
from pyspark.sql.dataframe import DataFrame

from common.module_a import get_litres_per_second


class TestGetLitresPerSecond(unittest.TestCase):
    def setUp(self):
        self.spark = SparkSession.builder.getOrCreate()

    def test_get_litres_per_second(self):
        test_data = [
            # pipe_id, start_time, end_time, litres_pumped
            (1, '2021-05-18 01:05:32', '2021-05-18 01:09:13', 10),
            (2, '2021-05-18 01:09:14', '2021-05-18 01:14:17', 20),
            (1, '2021-05-18 01:14:18', '2021-05-18 01:15:58', 30),
            (2, '2021-05-18 01:15:59', '2021-05-18 01:18:26', 40),
            (1, '2021-05-18 01:18:27', '2021-05-18 01:26:26', 60),
            (3, '2021-05-18 01:26:27', '2021-05-18 01:38:57', 60)
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
                'total_litres_pumped': 100,
                'avg_litres_per_second': 0.12
            },
            {
                'pipe_id': 2,
                'total_duration_seconds': 450,
                'total_litres_pumped': 60,
                'avg_litres_per_second': 0.13
            },
            {
                'pipe_id': 3,
                'total_duration_seconds': 750,
                'total_litres_pumped': 60,
                'avg_litres_per_second': 0.08
            },
        ])
        pd.testing.assert_frame_equal(expected_output_df, output_df_as_pd)
