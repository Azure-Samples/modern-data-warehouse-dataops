"""Test fixtures"""

import os
import pytest
from azure.identity import ClientSecretCredential
from azure.identity import DefaultAzureCredential

pytest_plugins = ['tests.dataconnectors.blob_storage', 'tests.dataconnectors.sql']

@pytest.fixture(scope="session")
def config():
    return {
        "AZ_SQL_SERVER_NAME": os.getenv("AZ_SQL_SERVER_NAME"),
        "AZ_SQL_SERVER_USERNAME": os.getenv("AZ_SQL_SERVER_USERNAME"),
        "AZ_SQL_SERVER_PASSWORD": os.getenv("AZ_SQL_SERVER_PASSWORD"),
        "AZ_SQL_DATABASE_NAME": os.getenv("AZ_SQL_DATABASE_NAME"),
        "AZ_SERVICE_PRINCIPAL_ID": os.getenv("AZ_SERVICE_PRINCIPAL_ID"),
        "AZ_SERVICE_PRINCIPAL_SECRET": os.getenv("AZ_SERVICE_PRINCIPAL_SECRET"),
        "AZ_SERVICE_PRINCIPAL_TENANT_ID": os.getenv("AZ_SERVICE_PRINCIPAL_TENANT_ID"),
        "AZ_SYNAPSE_NAME": os.getenv("AZ_SYNAPSE_NAME")
    }

@pytest.fixture(scope="module")
def azure_credential(config):
    client_id = config["AZ_SERVICE_PRINCIPAL_ID"] 
    client_secret = config["AZ_SERVICE_PRINCIPAL_SECRET"] 
    tenant_id = config["AZ_SERVICE_PRINCIPAL_TENANT_ID"] 
    if client_id is None or client_secret is None or tenant_id is None:
        print(f"###########using default")
        credentials = DefaultAzureCredential()
        return credentials
    else:
        credentials = ClientSecretCredential(
            client_id=client_id,
            client_secret=client_secret,
            tenant_id=tenant_id)
        return credentials

@pytest.fixture(scope="module")
def synapse_endpoint(config) -> str:
    synapse_name = config["AZ_SYNAPSE_NAME"] 
    endpoint = f"https://{synapse_name}.dev.azuresynapse.net"
    return endpoint
