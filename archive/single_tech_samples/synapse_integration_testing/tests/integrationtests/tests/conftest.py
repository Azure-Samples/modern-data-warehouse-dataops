"""Test fixtures"""

import os
import pytest
from azure.identity import ClientSecretCredential
from azure.identity import DefaultAzureCredential
from azure.synapse.artifacts import ArtifactsClient

pytest_plugins = [
    "dataconnectors.sql",
    "dataconnectors.adls",
    "dataconnectors.local_file",
]


@pytest.fixture(scope="session")
def config():
    return {
        "AZ_SYNAPSE_DEDICATED_SQLPOOL_SERVER": os.getenv(
            "AZ_SYNAPSE_DEDICATED_SQLPOOL_SERVER"
        ),
        "AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME": os.getenv(
            "AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME"
        ),
        "AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD": os.getenv(
            "AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD"
        ),
        "AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME": os.getenv(
            "AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME"
        ),
        "AZ_SERVICE_PRINCIPAL_CLIENT_ID": os.getenv("AZ_SERVICE_PRINCIPAL_CLIENT_ID"),
        "AZ_SERVICE_PRINCIPAL_SECRET": os.getenv("AZ_SERVICE_PRINCIPAL_SECRET"),
        "AZ_SERVICE_PRINCIPAL_TENANT_ID": os.getenv("AZ_SERVICE_PRINCIPAL_TENANT_ID"),
        "AZ_SYNAPSE_NAME": os.getenv("AZ_SYNAPSE_NAME"),
        "AZ_SYNAPSE_ENDPOINT_SUFFIX": os.getenv("AZ_SYNAPSE_ENDPOINT_SUFFIX"),
    }


@pytest.fixture(scope="module")
def azure_credential(config):
    client_id = config["AZ_SERVICE_PRINCIPAL_CLIENT_ID"]
    client_secret = config["AZ_SERVICE_PRINCIPAL_SECRET"]
    tenant_id = config["AZ_SERVICE_PRINCIPAL_TENANT_ID"]
    if client_id is None or client_secret is None or tenant_id is None:
        print("###########using default")
        credentials = DefaultAzureCredential()
        return credentials
    else:
        credentials = ClientSecretCredential(
            client_id=client_id, client_secret=client_secret, tenant_id=tenant_id
        )
        return credentials


@pytest.fixture(scope="module")
def synapse_endpoint(config) -> str:
    synapse_name = config["AZ_SYNAPSE_NAME"]
    synapse_endpoint_suffix = config["AZ_SYNAPSE_ENDPOINT_SUFFIX"]
    endpoint = f"https://{synapse_name}{synapse_endpoint_suffix}"
    return endpoint


@pytest.fixture(autouse=True)
def synapse_client(azure_credential, synapse_endpoint) -> ArtifactsClient:
    return ArtifactsClient(azure_credential, synapse_endpoint)
