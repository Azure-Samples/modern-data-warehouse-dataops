from cddp_solution.common.utils.custom_function import AbstractCustomFunction


class Function(AbstractCustomFunction):
    def __init__(self, app_config, func_config):
        super().__init__(app_config, func_config)

    def execute(self):
        pass

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

        pre_check_sql = "SELECT COUNT(*) FROM raw_fruits_1"
        raw_data = self.spark.sql(pre_check_sql)
        if raw_data.count() > 0:
            return True, None
        else:
            return False, "[Error] There's no data found for target table in STAGING zone."
