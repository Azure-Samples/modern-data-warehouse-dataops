from cddp_solution.common.utils.spark_job import AbstractSparkJob
from cddp_solution.common.utils import sink_data_helper
from cddp_solution.common.utils.module_helper import find_class
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
import logging
import inspect


class AbstractMasterDataCuration(AbstractSparkJob):
    def __init__(self, config):
        super().__init__(config)

    def load_data(self):
        """
        Load the processed data into temparory view from the Standard zone which is required for curated data
        generation in SQL way

        """

        self.logger.log(logging.INFO, f"## Master Curation Job {inspect.currentframe().f_code.co_name} started")

        transform_list = self.config["master_data_transform"]
        for data_transform in transform_list:
            self.load_storage_to_tempview(self.master_data_storage_path, data_transform["target"])

        self.logger.log(logging.INFO, f"## Master Curation Job {inspect.currentframe().f_code.co_name} succeeded")

    def transform(self):
        """
        Master data curation

        """
        self.logger.log(logging.INFO, f"## Master Curation Job {inspect.currentframe().f_code.co_name} started")

        curation_list = self.config["master_data_curation"]

        for master_data_curation in curation_list:
            if 'function' in master_data_curation:
                curation_module = master_data_curation['function']
                jobClz = find_class(curation_module, "Function")
                job = jobClz(self.config, master_data_curation)
                job.execute()

            elif 'sql' in master_data_curation:
                curation_sql = master_data_curation["sql"]
                curated_master_data_tablename = master_data_curation["target"]
                partition_keys = master_data_curation["partition_keys"]

                curated_data = self.spark.sql(curation_sql)

                # Add audit columns
                curated_data = self.add_audit_columns(curated_data, DataProcessingPhase.MASTER_STANDARD_TO_SERVING)

                db_tablename = f"{self.cz_dbname}.{curated_master_data_tablename}"
                target_table_path = f"{self.serving_data_storage_path}/{curated_master_data_tablename}"

                sink_data_helper.save_as_delta_table(
                    curated_data,
                    target_table_path,
                    db_tablename,
                    "overwrite",
                    partition_keys
                )

        self.logger.log(logging.INFO, "Master curated data has been sinked to serving zone properly")
        self.logger.log(logging.INFO, f"## Master Curation Job {inspect.currentframe().f_code.co_name} succeeded")
