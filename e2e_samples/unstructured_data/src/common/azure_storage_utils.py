from azure.storage.blob import BlobServiceClient


def get_blob_service_client(conn_string: str) -> BlobServiceClient:
    return BlobServiceClient.from_connection_string(conn_string)
