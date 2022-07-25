from abc import ABC
from cddp_solution.common.utils.Logger import Logger
from cddp_solution.common.utils import env
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
from pathlib import Path
from pyspark import SparkConf
from pyspark.sql import SparkSession
import pandas as pd
import io
import tempfile
from pyspark.sql import functions as F
import logging


class AbstractSparkJob(ABC):

    def __init__(self, config):
        self.config = config
        self.logger = Logger(config["domain"], config["customer_id"])

        # The folder structure will be like this
        # for data : customer_1/Standard/fruit/table_name/<files>
        # for bad_data : /customer_1/Standard/fruit/bad_data/table_name/<files>
        # - capture the data with schema mismatch errors
        # for invalid_data : /customer_1/Standard/fruit/invalid_data/table_name/<files>
        # - capture the data with business validation errors
        # for checkpoint : /customer_1/Standard/fruit/checkpoint/table_name/<files>
        self.bad_data_storage_name = "bad_data"
        self.invalid_data_storage_name = "invalid_data"
        self.checkpoint_name = "checkpoint"

        # Storage path should be in dbfs format (prefix with slash), if it's running on Databricks cluster
        if env.isRunningOnDatabricks():
            # Prepend ADLS mount path if relevant key has been set in configs
            if "adls_mount_path" in self.config:
                self.storage_dir_path = f'{config["adls_mount_path"]}/{config["customer_id"]}'
            else:
                self.storage_dir_path = f'/__data_storage__/{config["customer_id"]}'
        else:
            self.storage_dir_path = f'{tempfile.gettempdir()}/__data_storage__/{config["customer_id"]}'

        self.landing_data_storage_path = Path(
            self.storage_dir_path, "Landing",
            config["application_name"]).as_posix()

        # Follow the order of audit fields as per Data Model Sheet
        self.audit_cols = {
            "rz_master": {
                "create_ts": "rz_create_ts",
                "filename": "lz_filename",
                "md5": "md5_hash"
            },
            "pz_master": {
                "create_ts": "rz_create_ts",
                "filename": "lz_filename",
                "md5": "md5_hash",
                "active": "Is_active",
                "active_sts": "row_active_start_ts",
                "active_ets": "row_active_end_ts",
                "pz_create_ts": "pz_create_ts",
                "pz_update_ts": "pz_update_ts"
            },
            "rz_event": {
                "create_ts": "rz_create_ts",
                "filename": "lz_filename"
            },
            "pz_event": {
                "rz_create_ts": "rz_create_ts",
                "filename": "lz_filename",
                "pz_create_ts": "pz_create_ts",
                "pz_update_ts": "pz_update_ts"
            },
            "cz_event": {
                "create_ts": "cz_create_ts",
                "update_ts": "cz_update_ts"
            },
            "cz_master": {
                "create_ts": "cz_create_ts",
                "update_ts": "cz_update_ts"
            }
        }

        if "staging_data_storage_path" in config:
            self.staging_data_storage_path = Path(
                self.storage_dir_path, config["staging_data_storage_path"],
                config["application_name"]).as_posix()
        if "master_data_storage_path" in config:
            self.master_data_storage_path = Path(
                self.storage_dir_path, config["master_data_storage_path"],
                config["application_name"]).as_posix()
            self.master_data_bad_records_storage_path = Path(
                self.master_data_storage_path,
                self.bad_data_storage_name).as_posix()
            self.master_data_invalid_records_storage_path = Path(
                self.master_data_storage_path,
                self.invalid_data_storage_name).as_posix()
        if "event_data_storage_path" in config:
            self.event_data_storage_path = Path(
                self.storage_dir_path, config["event_data_storage_path"],
                config["application_name"]).as_posix()
        if "serving_data_storage_path" in config:
            self.serving_data_storage_path = Path(
                self.storage_dir_path, config["serving_data_storage_path"],
                config["application_name"]).as_posix()
        if "export_data_storage_csv_path" in config:
            self.export_data_storage_csv_path = Path(
                self.storage_dir_path, config["export_data_storage_csv_path"],
                config["application_name"]).as_posix()

        self.spark = SparkSession.getActiveSession()
        if not self.spark:
            conf = SparkConf().setAppName("data-app").setMaster("local[*]")
            self.spark = SparkSession.builder.config(conf=conf)\
                .config("spark.jars.packages",
                        "io.delta:delta-core_2.12:1.2.0,com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.21") \
                .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")\
                .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")\
                .config("spark.driver.memory", "24G")\
                .config("spark.driver.maxResultSize", "24G")\
                .enableHiveSupport()\
                .getOrCreate()

        self.rz_dbname = self.create_schema_if_not_exists(
            self.config["master_data_rz_database_name"])
        self.pz_dbname = self.create_schema_if_not_exists(
            self.config["master_data_pz_database_name"])
        self.cz_dbname = self.create_schema_if_not_exists(
            self.config["master_data_cz_database_name"])

        self.logger.log(logging.INFO, "Package spark_job initialized")

    def load_storage_to_tempview(self, storage_path, tablename):
        """
        Loads all data from a delta table to a temporary view.

        Parameters
        ----------
        storage_path :  str
           file path of the delta table to be loaded

        tablename : str
            name of the temp view to load data

        """
        data = self.load_storage(storage_path, tablename)
        data.createOrReplaceTempView(tablename)
        self.logger.log(logging.INFO, f"Temporary view created: {tablename}")

    def load_storage_to_tempview_scd2_latest(self,
                                             storage_path,
                                             tablename,
                                             key_hash_col_nm='key_hash',
                                             ts_col_nm='system_created_stamp'):
        """
        Loads latest data from a SCD2 format delta table to a temporary view.

        Parameters
        ----------
       storage_path :  str
           file path of the delta table to be loaded

        tablename : str
            name of the temp view to load data

        key_hash_col_nm : str
            name of `key_hash` column. The `key_hash` column is used in SCD2 format to identify data unit
            which will changes by time, by default 'key_hash'

        ts_col_nm : str
            name of `start` column. The `system_created_stamp` is used in SCD2 to mark the time when the
            change came in, by default 'system_created_stamp'

        """
        # data = self.load_storage(storage_path, tablename).filter(col("row_latest_ind") == 'Y')
        data = self.load_storage(storage_path, tablename)

        rz_col_create_ts = self.audit_cols["rz_master"]["create_ts"]
        rz_col_md5 = self.audit_cols["rz_master"]["md5"]

        data_latest = data.groupBy(rz_col_md5).agg(
            F.max(rz_col_create_ts).alias(rz_col_create_ts))
        data = data.join(data_latest, [rz_col_md5, rz_col_create_ts], 'inner')

        data.createOrReplaceTempView(tablename)

    def load_storage(self, storage_path, tablename):
        """
        Loads data from a delta table and returns it as a DataFrame.

        Parameters
        ----------
        storage_path :  str
           file path of the delta table to be loaded

        tablename : str
            name of the temp view to load data

        Returns
        ----------
        Spark Dataframe
            a Spark Dataframe which contains data of the delta table
        """

        self.logger.log(logging.INFO,
                        f"Load data from {storage_path}/{tablename}")
        return self.spark.read.format("delta").load(storage_path + "/" +
                                                    tablename)

    def load_csv_file(self, storage_path, badRecordsPath=None, schema=None):
        """
        Loads data from csv file and returns it as a Dataframe

        Parameters
        ----------
        storage_path :  str
           file path of the delta table to be loaded

        badRecordsPath : str
            path of the bad records, by default None

        schema : DataStructure
            schema to use when there is bad record, by default None


        Returns
        ----------
        Spark Dataframe
            a Spark Dataframe which contains data of the delta table
        """
        try:
            if badRecordsPath is not None and schema is not None:
                return self.spark.read.format("csv")\
                    .option("header", True)\
                    .schema(schema)\
                    .option("badRecordsPath", badRecordsPath)\
                    .load(storage_path)
            else:
                return self.spark.read.format("csv").option(
                    "header", True).load(storage_path)
        except Exception:
            self.logger.log(
                logging.ERROR,
                f"## Job Failed: Source file '{storage_path}' NOT found or source file has some issues"
            )
            return

    def load_csv_data(self, data_source, schema=None):
        """
        Loads data as csv format and returns it as a Dataframe

        Parameters
        ----------
        data_source : object
            configs of datasources

        schema : DataStructure
            --, by default None


        Returns
        ----------
        Spark Dataframe
            a Spark Dataframe which contains data of the delta table
        """
        data_str = data_source["data"]
        data = io.StringIO(data_str)
        pd_df = pd.read_csv(data, sep=",")
        df = self.spark.createDataFrame(pd_df)
        return df

    def dump_to_delta(self,
                      df,
                      target_table_path,
                      target_partition_keys_cols,
                      append=False):
        """
        Output data from Dataframe to delta table

        Parameters
        ----------
        df : Dataframe
            the target dataframe to be output

        target_table_path : str
            path of the delta table to which data will be overwritten

        target_partition_keys_cols : array
            list of key columns used as partition keys when saving to the delta table


        Returns
        ----------
        Dataframe
            the target dataframe to be output
        """
        mode = 'append' if append else 'overwrite'
        col = [x.upper() for x in df.columns]
        if len(target_partition_keys_cols) > 0:
            target_partition_keys = [
                x for x in col
                if x in set(target_partition_keys_cols.split(","))
            ]
            df.write.format("delta")\
                    .mode(mode)\
                    .partitionBy(target_partition_keys)\
                    .option("overwriteSchema", "true")\
                    .save(target_table_path)
        else:
            df.write.format("delta").mode(mode).option(
                "overwriteSchema", "true").save(target_table_path)

        return df

    def load_data_from_tempview(self, tempviewname):
        """
        load existing data tempview

        Parameters
        ----------
        tempviewname : string
            temp view name


        Returns
        ----------
        Dataframe
            the target dataframe to be output
        """
        return self.spark.sql(f"SELECT * FROM  {tempviewname}")

    def create_schema_if_not_exists(self, schema_name):
        """
        Creats schema if the given name not exists

        Parameters
        ----------
        schema_name : str
            name of the schema


        Returns
        ----------
        str
            name of the schema
        """
        self.spark.sql(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")
        return schema_name

    def add_audit_columns(self, dataframe,
                          data_processing_phase: DataProcessingPhase):
        """Add different audit columns to target dataframe according to
        different data processing phases and REORDER dataframe column names

        Parameters
        ----------
        dataframe : DataFrame
            Target dataframe

        data_processing_phase : DataProcessingPhase
            DataProcessingPhase enumerations, they are:
            - DataProcessingPhase.EVENT_LANDING_TO_STAGING
            - DataProcessingPhase.EVENT_STAGING_TO_STANDARD
            - DataProcessingPhase.EVENT_STANDARD_TO_SERVING

        Returns
        ----------
        DataFrame
            Updated dataframe with added columns
        """

        if data_processing_phase == DataProcessingPhase.EVENT_LANDING_TO_STAGING:
            col_create_ts_rz = self.audit_cols["rz_event"]["create_ts"]
            col_filename_rz = self.audit_cols["rz_event"]["filename"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_rz, F.current_timestamp())\
                                 .withColumn(col_filename_rz, F.input_file_name())

            # Column rearrange as per data model
            audit_cols = list(self.audit_cols["rz_event"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe

        elif data_processing_phase == DataProcessingPhase.EVENT_STAGING_TO_STANDARD:
            col_create_ts_pz = self.audit_cols["pz_event"]["pz_create_ts"]
            col_update_ts_pz = self.audit_cols["pz_event"]["pz_update_ts"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_pz, F.current_timestamp())\
                                 .withColumn(col_update_ts_pz, F.current_timestamp())

            # Event data column rearrange as per data model
            audit_cols = list(self.audit_cols["pz_event"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe

        elif data_processing_phase == DataProcessingPhase.EVENT_STANDARD_TO_SERVING:
            col_create_ts_cz = self.audit_cols["cz_event"]["create_ts"]
            col_update_ts_cz = self.audit_cols["cz_event"]["update_ts"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_cz, F.current_timestamp())\
                                 .withColumn(col_update_ts_cz, F.current_timestamp())

            # Event data column rearrange as per data model
            audit_cols = list(self.audit_cols["cz_event"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe

        elif data_processing_phase == DataProcessingPhase.MASTER_LANDING_TO_STAGING:
            col_create_ts_rz = self.audit_cols["rz_master"]["create_ts"]
            col_filename_rz = self.audit_cols["rz_master"]["filename"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_rz, F.current_timestamp())\
                                 .withColumn(col_filename_rz, F.input_file_name())

            # Column rearrange as per data model
            audit_cols = list(self.audit_cols["rz_master"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe

        elif data_processing_phase == DataProcessingPhase.MASTER_STAGING_TO_STANDARD:
            col_create_ts_pz = self.audit_cols["pz_master"]["pz_create_ts"]
            col_update_ts_pz = self.audit_cols["pz_master"]["pz_update_ts"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_pz, F.current_timestamp())\
                                 .withColumn(col_update_ts_pz, F.current_timestamp())

            # Event data column rearrange as per data model
            audit_cols = list(self.audit_cols["pz_master"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe

        elif data_processing_phase == DataProcessingPhase.MASTER_STANDARD_TO_SERVING:
            col_create_ts_cz = self.audit_cols["cz_master"]["create_ts"]
            col_update_ts_cz = self.audit_cols["cz_master"]["update_ts"]

            # Add audit fields
            dataframe = dataframe.withColumn(col_create_ts_cz, F.current_timestamp())\
                                 .withColumn(col_update_ts_cz, F.current_timestamp())

            # Master data column rearrange as per data model
            audit_cols = list(self.audit_cols["cz_master"].values())
            col_list = dataframe.columns
            col_list = audit_cols + [
                x for x in col_list if x not in audit_cols
            ]
            dataframe = dataframe.select(col_list)
            return dataframe
