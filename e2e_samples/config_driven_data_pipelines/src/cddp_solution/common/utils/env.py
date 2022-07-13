from dotenv import load_dotenv
import os
load_dotenv()


def get_evthub_connstr():
    """
    Get value of the EventHub connection string set in the environment variables.

    Returns
    ----------
    str
        value of environment variable `eventhubs.connectionString`
    """
    return os.getenv("eventhubs.connectionString")


def get_evthub_name():
    """
    Get value of the EventHub name set in the environment variables.

    Returns
    ----------
    str
        value of environment variable `eventhub.name`
    """
    return os.getenv("eventhub.name")


def getEnv(key):
    """
    Get value of environment variables.

    Parameters
    ----------
    key : str
        name of the environment variable


    Returns
    ----------
    str
        value of the environment variable
    """
    return os.getenv(key)


def isRunningOnDatabricks():
    """
    Check if is running on Databricks

    Returns
    ----------
    bool
    """
    return os.getenv("SPARK_HOME") == "/databricks/spark"
