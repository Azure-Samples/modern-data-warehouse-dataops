from cddp_solution.common.utils.Logger import Logger
from IPython.core.interactiveshell import InteractiveShell
import IPython
import json
import logging


def test_logging_info(caplog):
    # Test INFO logging
    logger = Logger("test_domain", "test_customer_id")
    with caplog.at_level(logging.INFO):
        logger.log(logging.INFO, "Test logging info.")

    log_message = json.loads(caplog.record_tuples[0][2])
    assert log_message["message"] == "Test logging info."
    assert log_message["source_system"] == "test_domain"
    assert log_message["customer_id"] == "test_customer_id"
    assert log_message["caller"] == "test_logger.py"


def test_logging_exception(caplog):
    # Test logging exceptions
    logger = Logger("test_domain", "test_customer_id")
    with caplog.at_level(logging.ERROR):
        logger.exception("Test logging exception!")

    log_message = json.loads(caplog.record_tuples[0][2])
    assert log_message["message"] == "Test logging exception!"
    assert log_message["source_system"] == "test_domain"
    assert log_message["customer_id"] == "test_customer_id"
    assert log_message["caller"] == "test_logger.py"


class MockNoteBookContext:
    @staticmethod
    def toJson():
        return """
            {
                "tags": {
                    "jobName": "mock_job_name",
                    "jobId": "mock_job_id",
                    "runId": "mock_run_id"
                }
            }
        """


class MockNoteBook:
    @staticmethod
    def getContext():
        return MockNoteBookContext()


class MockEntryPointDButils:
    @staticmethod
    def notebook():
        return MockNoteBook()


class MockEntryPointAttr:
    @staticmethod
    def getDbutils():
        return MockEntryPointDButils()


class MockNoteBookAttr:
    entry_point = MockEntryPointAttr()


class MockDButils:
    notebook = MockNoteBookAttr()


def test_logging_on_databricks(caplog, monkeypatch):
    """
    Test logging on Databricks via monkeypatch fixture to mock dbutils.notebook operations

    Parameters
    ----------
    caplog : Pytest fixture
        Captures log messages and displays them in their own section
    monkeypatch : Pytest fixture
        Helps to safely set/delete an attribute, dictionary item or environment variable
    """
    def mock_get_ipython():
        return InteractiveShell.instance()

    dbutils = MockDButils()
    # Mock environment variables to simulate it's running on Databricks
    monkeypatch.setenv("SPARK_HOME", "/databricks/spark")
    monkeypatch.setattr(IPython, "get_ipython", mock_get_ipython)
    monkeypatch.setitem(IPython.get_ipython().user_ns, "dbutils", dbutils)

    # Test logging errors
    logger = Logger("test_domain", "test_customer_id")
    with caplog.at_level(logging.ERROR):
        logger.log(logging.ERROR, "Test logging errors!")

    log_message = json.loads(caplog.record_tuples[0][2])
    assert log_message["message"] == "Test logging errors!"
    assert log_message["source_system"] == "test_domain"
    assert log_message["customer_id"] == "test_customer_id"
    assert log_message["job_name"] == "mock_job_name"
    assert log_message["job_id"] == "mock_job_id"
    assert log_message["task_run_id"] == "mock_run_id"
