from cddp_solution.common.utils.Config import Config
from pathlib import Path
from pyspark import SparkConf
from pyspark.sql import SparkSession
import pytest
import shutil
import tempfile


@pytest.fixture(autouse=False)
def cleanup_datalake():
    shutil.rmtree(f'{tempfile.gettempdir()}/__data_storage__/', ignore_errors=True)


@pytest.fixture(scope="session", autouse=False)
def get_test_resources_base_path():
    return Path(__file__).parent


@pytest.fixture(autouse=False)
def load_config(get_test_resources_base_path):
    """ Load configs from test json files
    """
    def _load_config(source_system, customer_id):
        metadata_configs = Config(source_system, customer_id, get_test_resources_base_path)
        return metadata_configs.load_config()

    return _load_config


@pytest.fixture(scope="session", autouse=False)
def clean_temp_paths():
    """ Clean temp paths for updated json files
    """
    def _clean_temp_paths(base_path, file_paths):
        for file_path in file_paths:
            target_temp_path = Path(base_path, Path(file_path).parent, "temp").as_posix()
            shutil.rmtree(target_temp_path, ignore_errors=True)

    return _clean_temp_paths


@pytest.fixture(scope="session", autouse=True)
def create_spark_session():
    spark = SparkSession.getActiveSession()
    if not spark:
        conf = SparkConf().setAppName("data-app").setMaster("local[*]")
        spark = SparkSession.builder.config(conf=conf)\
            .config("spark.jars.packages",
                    ("com.nimbusds:oauth2-oidc-sdk:9.37,"
                     "com.fasterxml.jackson.datatype:jackson-datatype-joda:2.13.0,"
                     "com.google.guava:guava:31.1-jre,"
                     "com.squareup.okhttp3:okhttp:3.13.0,"
                     "io.delta:delta-core_2.12:1.2.0,"
                     "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.21")) \
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")\
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")\
            .config("spark.driver.memory", "8G")\
            .config("spark.executor.memory", "2G")\
            .config("spark.driver.maxResultSize", "8G")\
            .getOrCreate()

    yield

    # Teardown: stop spark session
    # Teardown
    # Stop active streaming quires
    for active_streaming_query in spark.streams.active:
        active_streaming_query.stop()

    # Stop spark session
    spark.stop()
