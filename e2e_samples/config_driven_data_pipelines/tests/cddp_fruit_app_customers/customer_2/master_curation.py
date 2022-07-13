from cddp_solution.common.utils.custom_function import AbstractCustomFunction
from cddp_solution.common.utils.sink_data_helper import save_as_delta_table


class Function(AbstractCustomFunction):
    def __init__(self, app_config, func_config):
        super().__init__(app_config, func_config)

    def execute(self):
        transform_target = self.func_config["target"]
        partition_keys = "ID"
        data = self.spark.sql(
            "SELECT ID, Fruit, Colour, Price FROM fruits_2 where Colour='Green'"
        )

        db_tablename = f"{self.cz_dbname}.{transform_target}"
        target_table_path = f"{self.serving_data_storage_path}/{transform_target}"

        save_as_delta_table(
            data,
            target_table_path,
            db_tablename,
            mode="overwrite",
            partition_keys=partition_keys
        )
