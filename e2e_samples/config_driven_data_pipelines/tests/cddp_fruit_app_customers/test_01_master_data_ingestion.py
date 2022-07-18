from cddp_solution.common import master_data_ingestion_runner as ingestion_runner
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import tempfile
import sys


class TestMasterDataIngestion():
    SOURCE_SYSTEM = "cddp_fruit_app"
    APPLICATION_NAME = "fruit_app"
    CUSTOMER_ID = "customer_2"
    STAGING_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                 f"/Staging/{APPLICATION_NAME}")
    EXPECTED_INGESTED_ROWS = [
        ('Red Grape', 'Red', 2.5),
        ('Peach', 'Yellow', 3.5),
        ('Orange', 'Orange', 2.3),
        ('Green Apple', 'Green', 3.5),
        ('Fiji Apple', 'Red', 3.4),
        ('Banana', 'Yellow', 1.2),
        ('Green Grape', 'Green', 2.2)
    ]

    EXPECTED_INGESTED_ROWS_3 = [
        ('Peach', 'Yellow', 3.5),
        ('Orange', 'Orange', 2.3)
    ]

    def test_master_data_ingestion(self,
                                   cleanup_datalake,
                                   monkeypatch,
                                   get_test_resources_base_path):
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['ingestion_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            ingestion_runner.main()

        # Load ingested data
        spark = SparkSession.getActiveSession()
        ingested_fruits_1 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/raw_fruits_1")
        ingested_fruits_2 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/raw_fruits_2")
        ingested_fruits_3 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/raw_fruits_3")

        ingested_fruits_1.show()

        assert ingested_fruits_1.count() == 7
        self.assert_rows(ingested_fruits_1, self.EXPECTED_INGESTED_ROWS)

        assert ingested_fruits_2.count() == 7
        self.assert_rows(ingested_fruits_2, self.EXPECTED_INGESTED_ROWS)

        assert ingested_fruits_3.count() == 2
        # self.assert_rows(ingested_fruits_3, self.EXPECTED_INGESTED_ROWS_3)

    def assert_rows(self, target_df, expected_results):
        results_list = []
        collected_data = target_df.select(col("SHUIGUO"), col("YANSE"), col("JIAGE")) \
                                  .sort(col("ID")) \
                                  .collect()

        for data in collected_data:
            results_list.append((data.SHUIGUO, data.YANSE, data.JIAGE))
        print(results_list)
        assert results_list[0: 10] == expected_results
