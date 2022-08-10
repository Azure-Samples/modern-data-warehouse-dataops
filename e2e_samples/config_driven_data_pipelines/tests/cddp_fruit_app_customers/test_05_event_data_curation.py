from cddp_solution.common import event_data_curation_runner
from pyspark.sql import SparkSession
from tests.utils.test_utils import assert_rows
import tempfile
import sys


class TestEventDataCuration():
    SOURCE_SYSTEM = "cddp_fruit_app"
    APPLICATION_NAME = "fruit_app"
    CUSTOMER_ID = "customer_2"
    SERVING_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                 f"/Serving/{APPLICATION_NAME}")
    EXPECTED_CURATED_ROWS = [
        (5, "Fiji Apple", 184, 625.6),
        (2, "Peach", 142, 497.0),
        (1, "Red Grape", 194, 485.0)
    ]

    def test_event_data_curation(self,
                                 monkeypatch,
                                 get_test_resources_base_path):
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['event_data_curation_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            event_data_curation_runner.main()

        # Load curated data
        spark = SparkSession.getActiveSession()
        fruits_events_1 = spark.read.format("delta") \
                                    .load((f"{self.SERVING_STORAGE_BASE_PATH}/fruits_sales_1"))
        fruits_events_2 = spark.read.format("delta") \
                                    .load((f"{self.SERVING_STORAGE_BASE_PATH}/fruits_sales_2"))

        assert fruits_events_1.count() == 3
        assert_rows(fruits_events_1, ("ID", "Fruit", "sales_count", "sales_total"), self.EXPECTED_CURATED_ROWS)

        assert fruits_events_1.count() == 3
        assert_rows(fruits_events_2, ("ID", "Fruit", "sales_count", "sales_total"), self.EXPECTED_CURATED_ROWS)
