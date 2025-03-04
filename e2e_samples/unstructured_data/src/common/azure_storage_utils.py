from dataclasses import dataclass

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from common.config_utils import Fetcher


@dataclass
class AzureStorageConfig:
    account_url: str

    @classmethod
    def fetch(cls, fetcher: Fetcher) -> "AzureStorageConfig":
        return cls(account_url=fetcher.get_strict("AZURE_STORAGE_ACCOUNT_URL"))


def get_blob_service_client(config: AzureStorageConfig, credential: DefaultAzureCredential) -> BlobServiceClient:
    return BlobServiceClient(account_url=config.account_url, credential=credential)
