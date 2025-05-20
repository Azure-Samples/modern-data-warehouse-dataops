import argparse
import os
from typing import Generator, Union

from azure.devops.connection import Connection
from azure.devops.v7_0.git.models import GitVersionDescriptor
from azure.identity import DefaultAzureCredential
from azure.storage.filedatalake import DataLakeFileClient, DataLakeServiceClient, FileSystemClient
from dotenv import load_dotenv
from msrest.authentication import BasicAuthentication

load_dotenv()

# Environment variables
account_name = os.environ.get("ONELAKE_ACCOUNT_NAME")
workspace_id = os.environ.get("WORKSPACE_ID")
lakehouse_id = os.environ.get("LAKEHOUSE_ID")

# Azure Repo Details
organization_name = os.environ.get("GIT_ORGANIZATION_NAME")
personal_access_token = os.environ.get("GIT_PERSONAL_ACCESS_TOKEN")
project_name = os.environ.get("GIT_PROJECT_NAME")
repo_name = os.environ.get("GIT_REPO_NAME")
branch_name = os.environ.get("GIT_BRANCH_NAME")


def get_authentication_token() -> DefaultAzureCredential:
    """Get the default Azure credential for authentication."""
    return DefaultAzureCredential()


def get_file_system_client(token_credential: DefaultAzureCredential) -> FileSystemClient:
    """Get the file system client for Azure Data Lake Storage Gen2."""
    account_url = f"https://{account_name}.dfs.fabric.microsoft.com"
    service_client = DataLakeServiceClient(account_url, credential=token_credential)
    return service_client.get_file_system_client(workspace_id)

def get_azure_repo_connection(auth_method: str) -> Connection:
    """Establish a connection to Azure DevOps."""
    if auth_method == "oauth":
        oauth_token = os.environ.get("SYSTEM_ACCESSTOKEN")
        if not oauth_token:
            print("[E] OAuth token is missing. Ensure the pipeline has 'Allow scripts to access the OAuth token' enabled.")
            exit(1)  # Exit script if OAuth token is missing
        credentials = BasicAuthentication("", oauth_token)
        print("[I] Using OAuth token for authentication")
    else:
        credentials = BasicAuthentication("", personal_access_token)
        print("[I] Using Personal Access Token for authentication")

    organization_url = f"https://dev.azure.com/{organization_name}"
    return Connection(base_url=organization_url, creds=credentials)


def read_file_from_repo(connection: Connection, project_name: str, branch_name: str, src_file_name: str) -> Generator:
    """Read the file content from the Azure Repo."""
    git_client = connection.clients.get_git_client()
    version_descriptor = GitVersionDescriptor(version=branch_name, version_type="branch")
    return git_client.get_item_content(
        repository_id=repo_name, project=project_name, path=src_file_name, version_descriptor=version_descriptor
    )


def write_file_to_lakehouse(
    file_system_client: FileSystemClient,
    source_file_path: str,
    target_file_path: str,
    upload_from: str,
    connection: Union[Connection, None] = None,
) -> None:
    """Write the file to Fabric Lakehouse."""
    data_path = f"{lakehouse_id}/Files/{target_file_path}"
    file_client: DataLakeFileClient = file_system_client.get_file_client(data_path)

    if upload_from == "local":
        print(f"[I] Uploading local '{source_file_path}' to '{source_file_path}'")
        with open(source_file_path, "rb") as file:
            file_client.upload_data(file.read(), overwrite=True)
    elif upload_from == "git" and connection:
        print(f"[I] Uploading from git '{source_file_path}' to '{source_file_path}'")
        file_content = read_file_from_repo(connection, project_name, branch_name, source_file_path)
        content_str = "".join([chunk.decode("utf-8") for chunk in file_content])
        file_client.upload_data(content_str, overwrite=True)
    else:
        print(f"[E] Invalid upload_from value: '{upload_from}' or missing connection")


def read_from_fabric_lakehouse(file_system_client: FileSystemClient, target_file_path: str) -> None:
    """Read the file from Fabric Lakehouse."""
    data_path = f"{lakehouse_id}/Files/{target_file_path}"
    file_client: DataLakeFileClient = file_system_client.get_file_client(data_path)

    print(f"[I] Reading the file just uploaded from {data_path}")
    download = file_client.download_file()
    downloaded_bytes = download.readall()
    print(downloaded_bytes)


def main(source_file_path: str, target_file_path: str, upload_from: str, auth_method: str) -> None:
    """Main function to handle the workflow."""
    print(f"[I] Fabric workspace id: {workspace_id}")
    print(f"[I] Fabric lakehouse id: {lakehouse_id}")
    print(f"[I] Source file path: {source_file_path}")
    print(f"[I] Target file path: {target_file_path}")
    print(f"[I] Upload from: {upload_from}")
    print(f"[I] Authentication method: {auth_method}")

    # Initialize credentials and connections
    azure_repo_connection = (
        get_azure_repo_connection(auth_method) if upload_from == "git" else None
    )
    token_credential = get_authentication_token()
    file_system_client = get_file_system_client(token_credential)

    # Write and read operations
    write_file_to_lakehouse(
        file_system_client, source_file_path, target_file_path, upload_from, connection=azure_repo_connection
    )
    read_from_fabric_lakehouse(file_system_client, target_file_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Script to upload a local file or a file from Azure Repo to Fabric lakehouse."
    )
    parser.add_argument("source_file_path", type=str, help="The source file path of the local file or in the Azure Repo.")
    parser.add_argument("target_file_path", type=str, help="The target file path in the Fabric lakehouse.")
    parser.add_argument(
        "--upload_from",
        type=str,
        default="local",
        choices=["local", "git"],
        help="Specify the source of the file to upload: 'local' or 'git'. Default is 'local'.",
    )
    parser.add_argument(
        "--auth_method",
        type=str,
        default="pat",
        choices=["pat", "oauth"],
        help="Specify the authentication method: 'pat' (default) or 'oauth'.",
    )

    args = parser.parse_args()
    main(args.source_file_path, args.target_file_path, args.upload_from, args.auth_method)
