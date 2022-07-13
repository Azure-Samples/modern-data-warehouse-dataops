from cddp_solution.common.utils.custom_function import AbstractCustomFunction
from cddp_solution.common.utils import sink_data_helper
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
import logging
import inspect


class Function(AbstractCustomFunction):
    def __init__(self, app_config, func_config):
        super().__init__(app_config, func_config)

    def execute(self):
        self.logger.log(logging.INFO, f"## Event Curation Job {inspect.currentframe().f_code.co_name} started")

        event_data_curation_sql = """
            select m.ID, m.Fruit, sum(m.amount) as sales_count, sum(m.Price*m.amount) as sales_total
            from fruits_events_2 m group by m.ID, m.Fruit order by sales_total desc limit 3
        """

        curated_data = self.spark.sql(event_data_curation_sql)
        # Add audit columns
        curated_data = self.add_audit_columns(curated_data, DataProcessingPhase.EVENT_STANDARD_TO_SERVING)

        curated_data_tablename = self.func_config["target"]
        partition_keys = self.func_config["partition_keys"]
        db_tablename = f"{self.cz_dbname}.{curated_data_tablename}"
        target_table_path = f"{self.serving_data_storage_path}/{curated_data_tablename}"
        sink_data_helper.save_as_delta_table(curated_data,
                                             target_table_path,
                                             db_tablename,
                                             "overwrite",
                                             partition_keys)

        self.logger.log(logging.INFO, f"Data updated to {db_tablename} | Path: {target_table_path}")
        self.logger.log(logging.INFO, f"## Event Curation Job {inspect.currentframe().f_code.co_name} ended")

        return
