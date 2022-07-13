from cddp_solution.common.utils.spark_job import AbstractSparkJob
from abc import abstractmethod


class AbstractCustomFunction(AbstractSparkJob):
    def __init__(self, app_config, func_config):
        super().__init__(app_config)
        self.func_config = func_config

    @abstractmethod
    def execute(self):
        pass
