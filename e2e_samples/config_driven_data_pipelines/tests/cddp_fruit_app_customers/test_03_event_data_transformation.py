from cddp_solution.common import event_data_transformation_runner
from pyspark.sql import SparkSession
from tests.utils.test_utils import assert_rows
import tempfile
import sys


class TestEventDataTransformation():
    SOURCE_SYSTEM = "cddp_fruit_app"
    APPLICATION_NAME = "fruit_app"
    CUSTOMER_ID = "customer_2"
    STAGING_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                 f"/Staging/{APPLICATION_NAME}")
    STANDARD_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                  f"/Standard/{APPLICATION_NAME}")
    EXPECTED_STAGING_EVENTS_ROWS = [
        (7, 11),
        (7, 4),
        (7, 15),
        (7, 14),
        (7, 1),
        (7, 7),
        (7, 4),
        (7, 5),
        (7, 9),
        (7, 7)
    ]
    EXPECTED_TRANSFORMED_ROWS = [
        (7, "Green Grape", 2.2, 11),
        (7, "Green Grape", 2.2, 4),
        (7, "Green Grape", 2.2, 15),
        (7, "Green Grape", 2.2, 14),
        (7, "Green Grape", 2.2, 1),
        (7, "Green Grape", 2.2, 7),
        (7, "Green Grape", 2.2, 4),
        (7, "Green Grape", 2.2, 5),
        (7, "Green Grape", 2.2, 9),
        (7, "Green Grape", 2.2, 7)
    ]

    def test_event_data_transform(self,
                                  monkeypatch,
                                  get_test_resources_base_path):
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['event_data_transformation_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            event_data_transformation_runner.main()

        # Load raw event data
        spark = SparkSession.getActiveSession()
        raw_events_1 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/events_1")
        raw_events_2 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/events_2")

        assert raw_events_1.count() == 99
        assert_rows(raw_events_1, ("id", "amount"), self.EXPECTED_STAGING_EVENTS_ROWS)

        assert raw_events_2.count() == 99
        assert_rows(raw_events_2, ("id", "amount"), self.EXPECTED_STAGING_EVENTS_ROWS)

        # Load transformed event data
        spark = SparkSession.getActiveSession()
        fruits_events_1 = spark.read.format("delta") \
                                    .load(f"{self.STANDARD_STORAGE_BASE_PATH}/fruits_events_1")
        fruits_events_2 = spark.read.format("delta") \
                                    .load(f"{self.STANDARD_STORAGE_BASE_PATH}/fruits_events_2")

        assert raw_events_1.count() == 99
        assert_rows(fruits_events_1, ("ID", "Fruit", "Price", "amount"), self.EXPECTED_TRANSFORMED_ROWS)

        assert raw_events_2.count() == 99
        assert_rows(fruits_events_2, ("ID", "Fruit", "Price", "amount"), self.EXPECTED_TRANSFORMED_ROWS)
