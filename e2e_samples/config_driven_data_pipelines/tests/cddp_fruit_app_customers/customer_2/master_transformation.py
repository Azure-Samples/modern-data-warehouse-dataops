from cddp_solution.common.utils.custom_function import AbstractCustomFunction
from cddp_solution.common.utils.merge_to_scd2 import merge_to_scd2
import datetime


class Function(AbstractCustomFunction):
    def __init__(self, app_config, func_config):
        super().__init__(app_config, func_config)

    def execute(self):
        transform_target = self.func_config["target"]
        partition_keys = "ID"
        key_cols = "ID"
        data = self.spark.sql(
            "SELECT ID, shuiguo as Fruit, yanse as Colour, jiage as Price FROM raw_fruits_2"
        )
        current_time = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        data = merge_to_scd2(
            self.spark,
            data,
            self.master_data_storage_path + "/" + transform_target,
            self.pz_dbname,
            partition_keys,
            key_cols,
            current_time,
        )

    def replay_pre_check(self):
        """
        customized function to be executed before replay, to check/validate data.

        Returns
        ----------
        bool, str
            True, None : if data is ready to be replayed
            False, <Errormessage> : if data is not ready. pass error message in the 2nd parameter.


        Example
        ----------
        data = self.spark.sql("SELECT * FROM raw_fruits")
        if data.count() < 10:
            return False, f"There are merely non fruits"
        """
        return True, None

    def replay(self):
        transform_target = self.func_config["target"]
        partition_keys = []

        data = self.spark.sql(
            """
            SELECT ID, shuiguo as Fruit, jiage * 2 as Price,
            md5_hash,
            rz_create_ts as row_active_start_ts,
            LAG(rz_create_ts, -1, cast('9999-12-31 00:00:00.000000+00:00' as timestamp))
            OVER(PARTITION BY md5_hash ORDER BY md5_hash, rz_create_ts) AS row_active_end_ts
            FROM raw_fruits_2
            """
        )

        data = self.dump_to_delta(
            data, self.master_data_storage_path + "/" + transform_target, partition_keys
        )
