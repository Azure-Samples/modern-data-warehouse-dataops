from typing import Optional

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from common.config import AzureStorageConfig


def get_blob_service_client(
    config: Optional[AzureStorageConfig], credential: DefaultAzureCredential
) -> BlobServiceClient:
    if config is None:
        config = AzureStorageConfig()
    return BlobServiceClient(account_url=config.account_url, credential=credential)
