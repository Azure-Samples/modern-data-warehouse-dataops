from dataclasses import dataclass
from typing import Optional

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from common.config_utils import Fetcher


@dataclass
class AzureStorageConfig:
    account_url: Optional[str] = None
    conn_string: Optional[str] = None

    @classmethod
    def fetch(cls, fetcher: Fetcher) -> "AzureStorageConfig":
        account_url = fetcher.get("AZURE_STORAGE_ACCOUNT_URL")
        conn_string = fetcher.get("AZURE_STORAGE_CONNECTION_STRING")
        if account_url is None and conn_string is None:
            raise KeyError("Either 'AZURE_STORAGE_ACCOUNT_URL' or 'AZURE_STORAGE_CONNECTION_STRING' must be provided.")
        return cls(account_url=account_url, conn_string=conn_string)


def get_blob_service_client(
    config: AzureStorageConfig, credential: Optional[DefaultAzureCredential] = None
) -> BlobServiceClient:
    # try DefaultAzureCredential first
    if config.account_url is not None:
        if credential is None:
            credential = DefaultAzureCredential()
        return BlobServiceClient(account_url=config.account_url, credential=credential)
    # try connection string
    elif config.conn_string is not None:
        return BlobServiceClient.from_connection_string(config.conn_string)
    raise ValueError(
        "Invalid configuration: either an account URL or connection string must be provided for Azure Blob Storage"
    )
