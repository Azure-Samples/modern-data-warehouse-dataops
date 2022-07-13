from cddp_solution.common.utils.spark_job import AbstractSparkJob
from cddp_solution.common.utils.env import isRunningOnDatabricks
from cddp_solution.common.utils.module_helper import find_class
from cddp_solution.common.utils.schema_compare import validate_schema
from cddp_solution.common.utils import utility

from pyspark.sql import DataFrame
from pathlib import Path
import logging
import inspect


class AbstractMasterDataIngestion(AbstractSparkJob):
    def __init__(self, config):
        super().__init__(config)

        self.utl = utility.utility(config)

    def ingest(self):
        """
        Master data ingestion.
        This method will read master data sources configs under `master_data_source` of the "config.json"
        and perform ingestion.

        """
        self.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        if 'master_data_source' in self.config:
            data_source_list = self.config['master_data_source']

            for data_source in data_source_list:
                df = None
                table_name = data_source["table_name"]

                self.logger.log(logging.INFO, f"Master data ingestion for table name: {table_name}")
                # Assign default master data bad records path if it's not set explicitly in config.json
                badRecordsPath = data_source.get("badRecordsPath",
                                                 f'{self.master_data_bad_records_storage_path}/{table_name}')

                schema = None
                if "schema" in data_source:
                    schemaClz = find_class(data_source['schema'], "DataSchema")
                    schemaInstance = schemaClz(self.config)
                    schema = schemaInstance.get_schema()

                if data_source['type'] == 'csv':
                    df = self.load_csv_data(data_source, schema)
                    self.check_schema(data_source, df)

                elif data_source['type'] == 'csv-file':

                    location = data_source['location']
                    source_system = self.config["domain"]
                    resources_base_path = self.config["resources_base_path"]
                    location = Path(resources_base_path,
                                    f"{source_system}_customers",
                                    location).as_posix()

                    # When running on Databricks cluster,
                    # if resources location starts with /dbfs/, replace it with dbfs:/, by which pyspark APIs requires,
                    # otherwise add file: prefix to indicate resources are in local file system (wheel package
                    # installed path)

                    if isRunningOnDatabricks():
                        if str(resources_base_path).startswith("/dbfs/"):
                            location = location.replace("/dbfs/", "dbfs:/")
                        else:
                            location = f"file:{location}"

                    df = self.load_csv_file(location, badRecordsPath, schema)

                    # self.check_schema(data_source, df)

                elif data_source['type'].lower() == 'parquet':
                    location = self.utl.get_latest_file_from_folder(table_name, data_source['location'])

                    # If one file is missing then other files processing should not fail
                    if location is None:
                        self.logger.log(logging.ERROR,
                                        f"## Job Failed: Latest file '{table_name}' from the landing zone NOT found")
                        continue

                    if isRunningOnDatabricks():
                        if str(location).startswith("/dbfs/"):
                            location = location.replace("/dbfs/", "dbfs:/")
                        else:
                            location = f"file:{location}"

                    self.logger.log(logging.INFO, f"Reading source parquet file {location}")
                    df = self.spark.read.format("parquet").load(location)

                # If one file does not have data then other files processing should not fail
                if df is None or isinstance(df, DataFrame) is False or df.count() == 0:
                    self.logger.log(logging.ERROR,
                                    (f"## Job Failed: Source Dataframe '{table_name}' is empty or bad data, hence "
                                     "further processing ignored"))
                    continue
                else:
                    # self.logger.log(logging.INFO, f"Source data loaded from the location '{location}'")
                    self.logger.log(logging.INFO, "Source data loaded from the location")

                self.utl.transform_md5(df, data_source)

        self.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return

    def check_schema(self, data_source, df):
        """
        Checks schema of the specified Dataframe

        Parameters
        ----------
        data_source : dict
            configuration of data source object

        df : Dataframe
            target dataframe

        """
        if "schema" in data_source:
            schemaClz = find_class(data_source['schema'], "DataSchema")
            schemaInstance = schemaClz(self.config)
            schema = schemaInstance.get_schema()
            validate_schema(schema, df)

        return
