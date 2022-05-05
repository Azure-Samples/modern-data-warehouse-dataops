"""Test fixtures"""

import os
import time
import pytest

pytest_plugins = ['tests.dataconnectors.blob_storage', 'tests.dataconnectors.sql']

@pytest.fixture(scope="session")
def config():
    return {
        "AZ_SQL_SERVER_NAME": os.getenv("AZ_SQL_SERVER_NAME"),
        "AZ_SQL_SERVER_USERNAME": os.getenv("AZ_SQL_SERVER_USERNAME"),
        "AZ_SQL_SERVER_PASSWORD": os.getenv("AZ_SQL_SERVER_PASSWORD"),
        "AZ_SQL_DATABASE_NAME": os.getenv("AZ_SQL_DATABASE_NAME"),
    }
    