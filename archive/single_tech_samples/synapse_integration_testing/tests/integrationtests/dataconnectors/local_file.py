import pandas as pd


def read_local_file(file_path: str, file_name: str):
    """Read local file

    Args:
        file_name (str): File Name to Read

    Returns:
        file_name (str): Name of the File
        file_contents (bytes): Contents of the file
    """

    sample_data = f"{file_path}/{file_name}"

    print(f'READING LOCAL FILE: "{sample_data}"...')

    try:
        local_file = open(sample_data, "rb")
        file_contents = local_file.read()
        print(f'READ LOCAL FILE: "{sample_data}"')
        return file_name, file_contents
    except Exception as e:
        print(e)
        raise


def read_parquet_file(file_path: str, file_name: str):
    """Read local parquet file

    Args:
        file_name (str): File Name to Read

    Returns:
        df (DataFrame): Data Frame Of the file
    """

    sample_data = f"{file_path}/{file_name}"

    print("GETTING PARQUET DATA FRAME...")

    try:
        df = pd.read_parquet(sample_data, engine="pyarrow")
        print("GOT PARQUET DATA FRAME")
        return df
    except Exception as e:
        print(e)
        raise
