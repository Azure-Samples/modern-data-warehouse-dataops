import os
from pathlib import Path


def filter_files_by_type(folder_path: str | Path, file_types: list[str]) -> list[str]:
    """
    Retrieve a list of filenames of specified types in a local folder.

    Args:
    - folder_path (str): The path to the local folder.
    - file_types (list): A list of file types to look for (e.g., ['pdf', 'docx']).

    Returns:
    - list: A list of filenames of the specified types.
    """
    filenames = []
    for file in os.listdir(folder_path):
        if any(file.lower().endswith(f".{file_type.lower()}") for file_type in file_types):
            filenames.append(file)
    return filenames
