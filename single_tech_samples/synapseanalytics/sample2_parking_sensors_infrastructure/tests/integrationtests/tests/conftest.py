"""Test fixtures"""

import os
import pytest
from azure.identity import ClientSecretCredential
from azure.identity import DefaultAzureCredential
from azure.synapse.artifacts import ArtifactsClient

pytest_plugins = ['dataconnectors.sql', 'dataconnectors.adls', 'dataconnectors.local_file']

@pytest.fixture(scope="session")
def config():
    DEFAULT_AZ_SYNAPSE_POLL_INTERVAL_SEC = 5
    return {
        "AZ_SYNAPSE_DEDICATED_SQLPOOL_NAME": os.getenv("AZ_SYNAPSE_DEDICATED_SQLPOOL_NAME"),
        "AZ_SYNAPSE_DEDICATED_SQLPOOL_URI": os.getenv("AZ_SYNAPSE_DEDICATED_SQLPOOL_URI"),
        "AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME": os.getenv("AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME"),
        "AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD": os.getenv("AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD"),
        "AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME": os.getenv("AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME"),
        "AZ_SERVICE_PRINCIPAL_ID": os.getenv("AZ_SERVICE_PRINCIPAL_ID"),
        "AZ_SERVICE_PRINCIPAL_SECRET": os.getenv("AZ_SERVICE_PRINCIPAL_SECRET"),
        "AZ_SERVICE_PRINCIPAL_TENANT_ID": os.getenv("AZ_SERVICE_PRINCIPAL_TENANT_ID"),
        "AZ_SYNAPSE_NAME": os.getenv("AZ_SYNAPSE_NAME"),
        "AZ_SYNAPSE_URI": os.getenv("AZ_SYNAPSE_URI"),
        "AZURE_SYNAPSE_POLL_INTERVAL": os.getenv("AZURE_SYNAPSE_POLL_INTERVAL",
            DEFAULT_AZ_SYNAPSE_POLL_INTERVAL_SEC)
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
    synapse_uri = config["AZ_SYNAPSE_URI"] 
    endpoint = f"https://{synapse_name}.{synapse_uri}"
    return endpoint


@pytest.fixture(scope="module")
def synapse_status_poll_interval(config) -> int:
    return int(config["AZURE_SYNAPSE_POLL_INTERVAL"])


@pytest.fixture(autouse=True)
def synapse_client(azure_credential, synapse_endpoint) -> ArtifactsClient:
    return ArtifactsClient(azure_credential, synapse_endpoint)
