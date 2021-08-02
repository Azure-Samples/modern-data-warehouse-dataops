import os
import pytest
from azure.storage.blob import BlobServiceClient

@pytest.fixture(scope="module")
def blob_service_client():
    dest_cnstr = os.getenv("AZ_STORAGE_ACCOUNT_CONNECTIONSTRING")
    blob_service_client = BlobServiceClient.from_connection_string(dest_cnstr)

    return blob_service_client