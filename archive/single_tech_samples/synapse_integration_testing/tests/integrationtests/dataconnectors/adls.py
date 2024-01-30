from io import BytesIO
from typing import List
import logging
import os
import pytest
import pandas as pd
from azure.storage.filedatalake import DataLakeServiceClient
from dataconnectors import local_file


LOG = logging.getLogger(__name__)


@pytest.fixture(scope="module")
def adls_account_endpoint():
    ADLS_ACCOUNT_NAME = os.getenv("ADLS_ACCOUNT_NAME")
    ADLS_ACCOUNT_ENDPOINT_SUFFIX = os.getenv("ADLS_ACCOUNT_ENDPOINT_SUFFIX")
    return f"https://{ADLS_ACCOUNT_NAME}{ADLS_ACCOUNT_ENDPOINT_SUFFIX}/"


@pytest.fixture(scope="module")
def adls_connection_client(azure_credential, adls_account_endpoint):
    return DataLakeServiceClient(
        account_url=adls_account_endpoint,
        credential=azure_credential,
    )


def upload_to_ADLS(
    adls_connection_client: DataLakeServiceClient,
    container: str,
    file_path: str,
    file_name: str,
    base_path: str = None,
    file_contents: bytes = None,
):
    """Upload file to ADLS either by reading a local file or directly
    uploading the file contents

    Args:
        adls_connection_client (DataLakeServiceClient): ADLS Connection Object
        container (str): Container Name where file needs to be uploaded
        file_path (str): File Path of local file to upload
        file_name (str): File Name of local file to upload
        base_path (str) [optional - default is None]: Base Folder Path in ADLS where file will be uploaded
        file_contents (bytes) [optional - default is None]: Contents of the file
    Returns:
        request_id (str): Id of the ADLS upload request
    """

    print(
        "STARTING TO UPLOAD FILE TO ADLS"
        f"account: {adls_connection_client.url} "
        f"and container: {container}..."
    )

    try:
        file_system_client = adls_connection_client.get_file_system_client(
            file_system=container
        )

        if not base_path:
            file_client = file_system_client.create_file(f"{file_name}")
        else:
            file_client = file_system_client.get_directory_client(
                base_path
            ).create_file(f"{file_name}")

        if file_contents is None:
            file_name, file_contents = local_file.read_local_file(file_path, file_name)

        file_client.append_data(data=file_contents, offset=0, length=len(file_contents))
        response = file_client.flush_data(
            len(file_contents), close=True
        )  # close=True must be set to work with the Synapse Trigger's Topic Advanced Filter
        request_id = response.get("request_id")
        print(f"SUCCESSFULLY UPLOADED {file_name} with id {request_id} to ADLS")
        return request_id
    except Exception as e:
        print(e)
        raise


def download_from_ADLS(
    adls_connection_client: DataLakeServiceClient,
    container: str,
    file_name: str,
    base_path: str = "/",
):
    """Download file from ADLS

    Args:
        adls_connection_client (DataLakeServiceClient): ADLS Connection Object
        container (str): Container Name where file needs to be uploaded
        file_name (str): File Name to Upload
        base_path (str) [optional - default is "/"]: Base Folder Path in ADLS where file will be uploaded

    Returns:
        downloaded_bytes (bytes): Contents of the file
    """

    print(
        f"STARTING TO DOWNLOAD FILE {file_name}"
        f"FROM ADLS account: {adls_connection_client.url} "
        f"and container: {container}..."
    )

    try:
        file_system_client = adls_connection_client.get_file_system_client(
            file_system=container
        )

        directory_client = file_system_client.get_directory_client(base_path)

        file_client = directory_client.get_file_client(file_name)

        download = file_client.download_file()
        downloaded_bytes = download.readall()
        print(f"SUCCESSFULLY READ {file_name} FROM ADLS")
        return downloaded_bytes
    except Exception as e:
        print(e)
        raise


def get_parquet_df_from_contents(downloaded_bytes: bytes):
    """Convert File contents to Parquet data frame

    Args:
        downloaded_bytes (bytes): Contents of the file

    Returns:
        processed_df (bytes): DataFrame Of Read File
    """
    try:
        stream = BytesIO(downloaded_bytes)
        processed_df = pd.read_parquet(stream, engine="pyarrow")
        return processed_df
    except Exception as e:
        print(e)
        raise


def read_parquet_file_from_ADLS(
    adls_connection_client, container: str, file_name: str, base_path: str = "/"
):
    """Download file from ADLS and convert to parquet data frame

    Args:
        adls_connection_client (DataLakeServiceClient): ADLS Connection Object
        container (str): Container Name where file needs to be uploaded
        file_name (str): File Name to Upload
        base_path (str) [optional - default is "/"]: Base Folder Path in ADLS where file will be uploaded

    Returns:
        processed_df (bytes): DataFrame Of Read File
    """
    downloaded_bytes = download_from_ADLS(
        adls_connection_client, container, file_name, base_path
    )
    processed_df = get_parquet_df_from_contents(downloaded_bytes)
    return processed_df
