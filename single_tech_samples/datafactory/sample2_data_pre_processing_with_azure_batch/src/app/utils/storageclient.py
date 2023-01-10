"""Blob Storage client.
"""
import os
from azure.storage.blob import BlobServiceClient


class StorageClient:
    """Blob Storage client"""

    blobServiceClient: BlobServiceClient
    client: any

    def __init__(self, storageAccountUrl: str, credentials: any, containerName: str) -> None:
        """Constructor used to create storage and blob client.

        Args:
            storageAccountUrl (str): Url of the storage account
            credentials (any): Credentials for connecting to storage account.
            containerName (str): Name of the container.
        """
        self.blobServiceClient = BlobServiceClient(
            account_url=storageAccountUrl, credential=credentials
        )
        self.client = self.blobServiceClient.get_container_client(container=containerName)

    def getListOfFiles(self, path: str, fileType: str = None, recursive: bool = False) -> list:
        """Get a list of files from a given path.

        Args:
            path (str): Path of the stoarge account from which you want to get the list of files.
            fileType (str, optional): _description_. Defaults to None. Can be used to get certain file types,
            e.g ".bag" will list on bag files from storage account.

        Returns:
            list: List of files.
        """
        if not path == "" and not path.endswith("/"):
            path += "/"

        blob_iter = self.client.list_blobs(name_starts_with=path)
        files = []
        for blob in blob_iter:
            relative_path = blob.name.replace(path.lstrip("/"), "")
            if recursive:
                if fileType in relative_path:
                    files.append(relative_path)
            elif not "/" in relative_path:
                if fileType is None:
                    files.append(relative_path)
                elif relative_path.endswith(fileType):
                    files.append(relative_path)

        return files

    def getListOfDirectories(self, path, recursive=False) -> list:
        """Get list of directories from the given path

        Args:
            path (_type_): Path from which you want to get list of directories.
            recursive (bool, optional): _description_. Defaults to False.

        Returns:
            list: List of directories.
        """
        if not path == "" and not path.endswith("/"):
            path += "/"

        blob_iter = self.client.list_blobs(name_starts_with=path)
        dirs = []
        for blob in blob_iter:
            relative_dir = os.path.dirname(os.path.relpath(blob.name, path))
            if relative_dir and (recursive or not "/" in relative_dir) and not relative_dir in dirs:
                dirs.append(relative_dir)

        return dirs


    def getFirstLevelListOfDirectoryNames(self, path) -> list:
        """Get list of directory names from the given path

        Args:
            path (_type_): Path from which you want to get list of directories.
            recursive (bool, optional): _description_. Defaults to False.

        Returns:
            list: List of directories.
        """

        if not path == "" and not path.endswith("/"):
            path += "/"

        blob_iter = self.client.list_blobs(name_starts_with=path)
        dirset = set()
        for blob in blob_iter:
            relative_dir = os.path.dirname(os.path.relpath(blob.name, path))
            if relative_dir and (not "/" in relative_dir):
                dirName = relative_dir.split("\\")[0]
                dirset.add(dirName)

        return list(dirset)
