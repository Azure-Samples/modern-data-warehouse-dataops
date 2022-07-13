import inspect
import json
import logging
from cddp_solution.common.utils import env
from cddp_solution.common.utils.spark_log4j_handler import spark_log4j_handler
from pathlib import Path
from pyspark.sql import SparkSession


class Logger():
    def __init__(self,
                 domain,
                 customer_id):
        self.__domain = domain
        self.__customer_id = customer_id
        self.__job_name = None
        self.__job_id = None
        self.__task_run_id = None
        self.__log4j_handler = None
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)

        formatter = logging.Formatter('%(asctime)s [%(levelname)s]: %(message)s')
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(formatter)
        if not self.logger.hasHandlers():
            self.logger.addHandler(stream_handler)

        if env.isRunningOnDatabricks() and not self.__log4j_handler:
            spark = SparkSession.getActiveSession()
            self.__log4j_handler = spark_log4j_handler(spark)

            if len(self.logger.handlers) < 2:
                self.logger.addHandler(self.__log4j_handler)

    def log(self, log_level, log_message):
        """
        Log message with log level

        Parameters
        ----------
        log_level : int
            Python logging level, like logging.INFO, logging.ERROR, etc.
        log_message: str
            Logging message
        """
        extra_block = self.__prepare_extra_log_info()

        # Add custom_dimensions to log message dictionary
        log_message_with_custom_dimensions = extra_block["custom_dimensions"]
        log_message_with_custom_dimensions["message"] = log_message
        self.logger.log(log_level, json.dumps(log_message_with_custom_dimensions))

    def exception(self, exception_message):
        """ Log exceptions

        Parameters
        ----------
        exception_message: str
            Logging message
        """
        extra_block = self.__prepare_extra_log_info()

        # Add custom_dimensions to exception message dictionary
        exception_message_with_custom_dimensions = extra_block["custom_dimensions"]
        exception_message_with_custom_dimensions["message"] = exception_message
        self.logger.exception(json.dumps(exception_message_with_custom_dimensions))

    def __prepare_extra_log_info(self):
        self.__get_job_and_task_run_info()
        caller_name = self.__get_caller()
        return {"custom_dimensions": {"source_system": self.__domain,
                                      "customer_id": self.__customer_id,
                                      "job_name": self.__job_name,
                                      "job_id": self.__job_id,
                                      "task_run_id": self.__task_run_id,
                                      "caller": caller_name}}

    def __get_job_and_task_run_info(self):
        """
        Fetch job name, id and task run id if it's running as Databricks job, otherwise
        all values would be None

        """
        job_name = None
        job_id = None
        task_run_id = None
        if env.isRunningOnDatabricks():
            import IPython

            dbutils = IPython.get_ipython().user_ns["dbutils"]
            context = dbutils.notebook.entry_point.getDbutils().notebook().getContext().toJson()
            context_json = json.loads(context)
            tags = context_json.get("tags")

            if tags:
                job_name = tags.get("jobName")
                job_id = tags.get("jobId")
                task_run_id = tags.get("runId")

        self.__job_name = job_name
        self.__job_id = job_id
        self.__task_run_id = task_run_id

    def __get_caller(self):
        """
        Get actual logging caller from calling stack

        Parameters
        ----------

        Returns
        ----------
        str
            Logging caller Python file name
        """
        stack = inspect.stack()
        caller_path = stack[3][1]

        return Path(caller_path).name
