from cddp_solution.common import master_data_ingestion_runner as ingestion_runner
from cddp_solution.common import master_data_transformation_runner
from pathlib import Path
from pyspark.sql import SparkSession
from tests.utils.test_utils import assert_rows
import tempfile
import sys


class TestMasterDataTransformation():
    SOURCE_SYSTEM = "tests.cddp_fruit_app"
    APPLICATION_NAME = "fruit_app"
    CUSTOMER_ID = "customer_2"
    STAGING_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                 f"/Staging/{APPLICATION_NAME}")
    STANDARD_STORAGE_BASE_PATH = (f"{tempfile.gettempdir()}/__data_storage__/{CUSTOMER_ID}"
                                  f"/Standard/{APPLICATION_NAME}")
    EXPECTED_TRANSFORMED_ROWS = [
        ('Red Grape', 2.5),
        ('Peach', 3.5),
        ('Orange', 2.3),
        ('Green Apple', 3.5),
        ('Fiji Apple', 3.4),
        ('Banana', 1.2),
        ('Green Grape', 2.2)
    ]

    EXPECTED_TRANSFORMED_ROWS_2 = [
        ('Red Grape', 2.5),
        ('Peach', 3.5),
        ('Orange', 2.3),
        ('Green Apple', 3.5),
        ('Fiji Apple', 3.4),
        ('Banana', 1.2),
        ('Green Grape', 2.2),
        ('Strawberry', 10.2)
    ]

    def test_master_data_transform(self,
                                   monkeypatch,
                                   get_test_resources_base_path):
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['master_data_transformation_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            master_data_transformation_runner.main()

        # Load transformed data
        spark = SparkSession.getActiveSession()
        transformed_fruits_1 = spark.read.format("delta").load(f"{self.STANDARD_STORAGE_BASE_PATH}/fruits_1")
        transformed_fruits_2 = spark.read.format("delta").load(f"{self.STANDARD_STORAGE_BASE_PATH}/fruits_2")

        assert transformed_fruits_1.count() == 7
        assert_rows(transformed_fruits_1.select("Fruit", "Price").sort("ID"),
                    ("Fruit", "Price"),
                    self.EXPECTED_TRANSFORMED_ROWS)

        assert transformed_fruits_2.count() == 7
        assert_rows(transformed_fruits_2.select("Fruit", "Price").sort("ID"),
                    ("Fruit", "Price"),
                    self.EXPECTED_TRANSFORMED_ROWS)

        # Ingest data a 2nd time to test raw table already existed condition
        self.add_new_source_data(get_test_resources_base_path)
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['ingestion_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path])
            ingestion_runner.main()

        ingested_fruits_1 = spark.read.format("delta").load(f"{self.STAGING_STORAGE_BASE_PATH}/raw_fruits_1")

        assert ingested_fruits_1.count() == 8
        assert_rows(ingested_fruits_1, ('SHUIGUO', 'JIAGE'), self.EXPECTED_TRANSFORMED_ROWS_2)

        # Transform a 2nd time to test table already exists use case
        with monkeypatch.context() as mockcontext:
            mockcontext.setattr(sys, 'argv', ['master_data_transformation_runner',
                                              self.SOURCE_SYSTEM,
                                              self.CUSTOMER_ID,
                                              get_test_resources_base_path,
                                              "fruits_1"])
            master_data_transformation_runner.main()

        transformed_fruits_1 = spark.read.format("delta").load(f"{self.STANDARD_STORAGE_BASE_PATH}/fruits_1")
        transformed_fruits_1.sort("ID").show()
        assert transformed_fruits_1.count() == 8
        assert_rows(transformed_fruits_1.select("Fruit", "Price").sort("ID"),
                    ("Fruit", "Price"),
                    self.EXPECTED_TRANSFORMED_ROWS_2)

        # Cleaning activity
        self.remove_new_source_data(get_test_resources_base_path)

    def add_new_source_data(self, test_resources_base_path):
        """
        Add new row to existed master source data to simulate master data updates from source system

        Parameters:
        ----------
        test_resources_base_path : str
            Test resources base path
        """
        with open(Path(test_resources_base_path,
                       f"cddp_fruit_app_customers/{self.CUSTOMER_ID}/config.json").as_posix(),
                  "r+") as configs:
            lines = configs.readlines()
            configs.seek(0)
            for line in lines:
                if "ID,shuiguo,yanse,jiage" in line:
                    line = line.replace("\",", "\\n8,Strawberry,Red,10.2\",")
                configs.write(line)
            configs.truncate()

    def remove_new_source_data(self, test_resources_base_path):
        """
        Remove new added row from source data for next test

        Parameters:
        ----------
        test_resources_base_path : str
            Test resources base path
        """
        with open(Path(test_resources_base_path,
                       f"cddp_fruit_app_customers/{self.CUSTOMER_ID}/config.json").as_posix(),
                  "r+") as configs:
            lines = configs.readlines()
            configs.seek(0)
            for line in lines:
                if "ID,shuiguo,yanse,jiage" in line:
                    line = line.replace("\\n8,Strawberry,Red,10.2\",", "\",")
                configs.write(line)
            configs.truncate()
