from abc import abstractmethod
from ...common.utils.spark_job import AbstractSparkJob


class AbstractExportJob(AbstractSparkJob):
    @abstractmethod
    def export(self, df):
        pass
