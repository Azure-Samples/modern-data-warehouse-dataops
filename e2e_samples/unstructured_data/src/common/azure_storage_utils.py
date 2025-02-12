from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


def get_blob_service_client(account_url: str) -> BlobServiceClient:
    credential = DefaultAzureCredential()
    return BlobServiceClient(account_url=account_url, credential=credential)
