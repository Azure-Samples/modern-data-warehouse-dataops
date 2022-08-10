from cddp_solution.common import master_data_curation_runner
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import tempfile
import sys


class TestMasterDataCuration():
    SOURCE_SYSTEM = "cddp_fruit_app"
    APPLICATION_NAME = "fruit_app"
    CUSTOMER_ID = "customer_2"
    SERVING_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                 f"/Serving/{APPLICATION_NAME}")

    # test case for master_curation is before master_data_replay test case because replay changes the
    #  values, which leads to different expected rows.
    EXPECTED_CURATED_ROWS = [
        ('Green Apple', 'Green', 3.5),
        ('Green Grape', 'Green', 2.2)
    ]

    def test_master_data_curation(self,
                                  monkeypatch,
                                  get_test_resources_base_path):
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['master_data_curation_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            master_data_curation_runner.main()

        # Load curated data
        spark = SparkSession.getActiveSession()
        green_fruits_1 = spark.read.format("delta") \
            .load((f"{self.SERVING_STORAGE_BASE_PATH}/green_fruits_1"))
        green_fruits_2 = spark.read.format("delta") \
            .load((f"{self.SERVING_STORAGE_BASE_PATH}/green_fruits_2"))

        assert green_fruits_1.count() == 2
        self.assert_rows(green_fruits_1, self.EXPECTED_CURATED_ROWS)

        assert green_fruits_2.count() == 2
        self.assert_rows(green_fruits_2, self.EXPECTED_CURATED_ROWS)

    def assert_rows(self, target_df, expected_results):
        results_list = []
        collected_data = target_df.select(col("Fruit"), col("Colour"), col("Price")) \
                                  .sort(col("ID")) \
                                  .collect()

        for data in collected_data:
            results_list.append((data.Fruit, data.Colour, data.Price))

        assert results_list[0: 10] == expected_results
