import os
import pytest
from azure.storage.blob import BlobServiceClient


@pytest.fixture(scope="module")
def blob_service_client():
    account_name = os.getenv("AZ_STORAGE_ACCOUNT_NAME")
    account_key = os.getenv("AZ_STORAGE_ACCOUNT_KEY")

    blob_service_client = BlobServiceClient(
        account_url="https://" + account_name + ".blob.core.windows.net",
        credential=account_key
    )
    return blob_service_client
