import pytest
import pyodbc


@pytest.fixture(scope="module")
def sql_connection(config):
    """Create a Connection Object object"""
    server = config["AZ_SQL_SERVER_NAME"]  # 'tcp:myserver.database.windows.net', 'localhost\sqlexpress'
    database = config["AZ_SQL_DATABASE_NAME"]
    username = config["AZ_SQL_SERVER_USERNAME"]
    password = config["AZ_SQL_SERVER_PASSWORD"]
    cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server +
                          ';DATABASE='+database+';UID='+username+';PWD=' + password)
    yield cnxn
    cnxn.close()
