from dataclasses import dataclass
from typing import Optional

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from common.env import AZURE_STORAGE_ACCOUNT_URL


@dataclass
class AzureStorageConfig:
    account_url: str

    @classmethod
    def from_env(cls) -> "AzureStorageConfig":
        return cls(
            account_url=AZURE_STORAGE_ACCOUNT_URL.get_strict(),
        )


def get_blob_service_client(
    config: Optional[AzureStorageConfig], credential: DefaultAzureCredential
) -> BlobServiceClient:
    if config is None:
        config = AzureStorageConfig.from_env()
    return BlobServiceClient(account_url=config.account_url, credential=credential)
