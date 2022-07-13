import logging
from logging import Handler, LogRecord
from pyspark.sql import SparkSession


class spark_log4j_handler(Handler):
    """Handler for Log4j logger

    Parameters
    ----------
    Handler : Handler
        Base handler class
    """
    def __init__(self, spark_session: SparkSession):
        Handler.__init__(self)
        self.log_manager = spark_session.sparkContext._jvm.org.apache.log4j.LogManager

    def emit(self, record: LogRecord):
        """ Implement emit method of base Handler class to log different levels of log messages

        Parameters
        ----------
        record : LogRecord
            Logging record
        """
        logger = self.log_manager.getLogger(__name__)
        if record.levelno == logging.CRITICAL:
            logger.fatal(record.getMessage())
        elif record.levelno == logging.ERROR:
            logger.error(record.getMessage())
        elif record.levelno == logging.WARNING:
            logger.warn(record.getMessage())
        elif record.levelno == logging.INFO:
            logger.info(record.getMessage())
        elif record.levelno == logging.DEBUG:
            logger.debug(record.getMessage())
