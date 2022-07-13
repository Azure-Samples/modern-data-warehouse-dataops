# Adding Try Catch to avoid the entire job failures, so that Framework could process other data sets smoothly.
from cddp_solution.common.utils.spark_job import AbstractSparkJob
from cddp_solution.common.utils.module_helper import find_class
from cddp_solution.common.utils import utility
from cddp_solution.common.utils import sink_data_helper

from pyspark.sql import functions as F
import datetime
import logging
import os
import inspect


class AbstractMasterDataTransformation(AbstractSparkJob):
    def __init__(self, config):
        super().__init__(config)
        self.utl = utility.utility(config)

    def load_data(self):
        """

        Loads master data as temporary view from sources defined in the configuration

        """

        # load data from the Staging zone and create temporary view to perform master_data_transform
        if 'master_data_source' in self.config:
            data_source_list = self.config['master_data_source']
            for data_source in data_source_list:
                try:
                    self.load_storage_to_tempview_scd2_latest(self.staging_data_storage_path, data_source["table_name"])
                except Exception as e:
                    self.logger.log(logging.ERROR,
                                    f"## Job failed in load_data {data_source['table_name']} exception is\n{e}")

    def validate_master_data(self):
        """

        Validate invalid_data records
        Get valid data from loaded data then replace the dataframe in case of need filter out invalid records data
        Last Save invalid data to the table

        """

        if "master_data_validate" not in self.config:
            return
        for master_data_validate in self.config["master_data_validate"]:
            if 'valid_sql' in master_data_validate and 'table_name' in master_data_validate:
                original_data = self.load_data_from_tempview(master_data_validate["table_name"])

                # Get the valid records
                valid_records = self.spark.sql(master_data_validate["valid_sql"])
                # Get and save the invalid records
                invalid_records = original_data.select(original_data.columns)\
                                               .subtract(valid_records.select(original_data.columns))
                if invalid_records.count() != 0:
                    self.save_invalid_records(invalid_records, master_data_validate)

                valid_records.createOrReplaceTempView(master_data_validate["valid_target"])

    def save_invalid_records(self, df, data_validate):
        """

        Save the invalid records into delta table

        Parameters
        ----------
        df : dataframe
            invalid records dataframe

        data_validate : config
            data validation config read from config.json

        record_format : str
            csv or json, by default 'json'

        """

        self.logger.log(logging.INFO, "Saving invalid records for retry.")
        invalid_target = data_validate["invalid_target"]
        df = df.withColumn("record", F.to_json(F.struct(df.columns))).select(F.col('record'))
        df = df \
            .withColumn("rule", F.lit(data_validate["valid_sql"])) \
            .withColumn("reason", F.lit(data_validate["reason"])) \
            .withColumn("status", F.lit("retryable")) \
            .withColumn("retry_attempt", F.lit(0)) \
            .withColumn("retry_attempt_limit", F.lit(3)) \
            .withColumn("created_at", F.current_timestamp()) \

        path = os.path.join(self.master_data_storage_path, invalid_target)

        sink_data_helper.save_as_delta_table(df,
                                             path,
                                             f"{self.pz_dbname}.{invalid_target}")

    def transform(self, targets=None):
        """

        Master data transformation.
        This method will read transformation configs under `master_data_transform` of the "config.json" and perform
        the transformation one by one.
        Transformation can be defined either in `function` type or in `sql` type

        Parameters
        ----------
        targets : array[str]
            list of specified targets which to perform transformation. If set to None will run transformation
            to all, by default None

        """

        self.logger.log(logging.INFO, f"## Master {inspect.currentframe().f_code.co_name} job started")

        transform_list = self.config["master_data_transform"]

        self.target_transform_list = []
        if targets:
            for data_transform in transform_list:
                if data_transform["target"] in targets:
                    self.target_transform_list.append(data_transform)
        else:
            self.target_transform_list = transform_list

        for data_transform in self.target_transform_list:
            if 'function' in data_transform:
                transform_module = data_transform['function']
                jobClz = find_class(transform_module, "Function")
                job = jobClz(self.config, data_transform)
                job.execute()

            elif 'sql' in data_transform:
                transform_sql = data_transform["sql"]
                transform_target = data_transform["target"]
                partition_keys = data_transform["partition_keys"]
                key_cols = data_transform["key_cols"]

                self.logger.log(logging.INFO, f"Master data transformation for the table: {transform_target}")

                # FIXME: Put this under the merge_to_scd2 function
                current_time = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
                target_table_path = f"{self.master_data_storage_path}/{transform_target}"

                data = self.spark.sql(transform_sql)

                # This check is needed to avoid the unexpected break inside SCD2 logic
                if data.count() > 0:
                    # FIXME: Need to limit the no. of parameters passing to the method
                    self.utl.merge_to_scd2(data,
                                           target_table_path,
                                           transform_target,
                                           self.pz_dbname,
                                           partition_keys,
                                           key_cols,
                                           current_time)
                else:
                    self.logger.log(logging.INFO, f"No records found from {transform_sql}")

        self.logger.log(logging.INFO, f"## Master {inspect.currentframe().f_code.co_name} job ended")

    def export(self):
        """

        Loads data from transformation targets and returns a list of Dataframe

        Returns
        ----------
        array
            list of Dataframe

        """

        if not self.target_transform_list:
            self.target_transform_list = self.config["master_data_transform"]

        idx = 0
        data_list = []
        while idx < len(self.target_transform_list):
            transform_target = self.target_transform_list[idx]["target"]
            data = self.load_storage(self.master_data_storage_path, transform_target)
            data_list.append(data)
            idx += 1

        return data_list
