import pytest
import pyodbc


@pytest.fixture(scope="module")
def sql_connection(config):
    """Create a Connection Object object"""
    server = config["AZ_SYNAPSE_DEDICATED_SQLPOOL_NAME"]  # ex: {synapseworkspacename}.sql.azuresynapse.net
    database = config["AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME"]
    username = config["AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME"]
    password = config["AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD"]
    cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server +
                          ';DATABASE='+database+';UID='+username+';PWD=' + password)
    yield cnxn
    cnxn.close()
