from cddp_solution.common.utils.custom_function import AbstractCustomFunction
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
from cddp_solution.common.utils import sink_data_helper
import logging


class Function(AbstractCustomFunction):
    def __init__(self, app_config, func_config):
        super().__init__(app_config, func_config)
        self.__event_data_transform_sql = f"""
        select m.ID, m.Fruit, m.Price, e.amount, e.ts, e.rz_create_ts, e.lz_filename from {self.func_config["source"]} e
            left outer join fruits_2 m
                ON e.id=m.ID
                and m.row_active_start_ts<=e.ts
                and m.row_active_end_ts>e.ts
        """

    def execute(self):
        event_data_table_name = self.func_config["target"]
        partition_keys = self.func_config["partition_keys"]

        transformed_data = self.spark.sql(self.__event_data_transform_sql)
        # Add audit columns
        transformed_data = self.add_audit_columns(transformed_data, DataProcessingPhase.EVENT_STAGING_TO_STANDARD)
        streaming_query = sink_data_helper.save_as_streaming_delta_table(
                    transformed_data,
                    f"{self.event_data_storage_path}/{event_data_table_name}",
                    f"{self.event_data_storage_path}/{self.checkpoint_name}/{event_data_table_name}",
                    f"{self.pz_dbname}.{event_data_table_name}",
                    partition_keys)

        self.logger.log(logging.INFO, "Events streaming data is transforming and sinking to delta table properly.")
        return streaming_query

    def replay(self, from_timestamp, to_timestamp, event_table_name, event_table_timestamp_col):
        """ Replay transformation with events/facts data fetched from staging zone by given replay from and to timestamp

        Parameters
        ----------
        from_timestamp:
            Replay FROM timestamp
        to_timestamp:
            Replay TO timestamp
        event_table_name: string
            Target events/facts delta table name in staging zone
        event_table_timestamp_col: string
            Timestamp column name of the target events/facts delta table
        """
        # Load events/facts from staging zone by input from and to timestamp
        events = self.spark.read.format("delta").load(f"{self.staging_data_storage_path}/{event_table_name}")
        target_events = events.filter((f"{event_table_timestamp_col} >= '{from_timestamp}' and "
                                       f"{event_table_timestamp_col} <= '{to_timestamp}'"))
        target_events.createOrReplaceTempView(event_table_name)

        # Replay transformation using the loaded raw events
        replayed_df = self.spark.sql(self.__event_data_transform_sql)

        return replayed_df
