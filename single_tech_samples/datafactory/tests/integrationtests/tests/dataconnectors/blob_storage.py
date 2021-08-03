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
    # dest_cnstr = os.getenv("AZ_STORAGE_ACCOUNT_CONNECTIONSTRING")
    # blob_service_client = BlobServiceClient.from_connection_string(dest_cnstr)
    return blob_service_client

# remove cnstr logic
# ref -- https://docs.microsoft.com/en-us/python/api/overview/azure/storage-blob-readme?view=azure-python