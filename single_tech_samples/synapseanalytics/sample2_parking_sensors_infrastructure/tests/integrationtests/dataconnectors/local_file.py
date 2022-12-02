import pandas as pd


def read_local_file(file_name: str):
    """Read local file

    Args:
        file_name (str): File Name to Read

    Returns:
        file_name (str): Name of the File
        file_contents (bytes): Contents of the file
    """

    sample_data = f"data/{file_name}"

    print(f'READING LOCAL FILE: "{sample_data}"...')

    try:
        local_file = open(sample_data, "rb")
        file_contents = local_file.read()
        print(f'READ LOCAL FILE: "{sample_data}"')
        return file_name, file_contents
    except Exception as e:
        print(e)
        raise


def read_parquet_file(file_name: str):
    """Read local parquet file

    Args:
        file_name (str): File Name to Read

    Returns:
        df (DataFrame): Data Frame Of the file
    """

    sample_data = f"data/{file_name}"

    print("GETTING PARQUET DATA FRAME...")

    try:
        df = pd.read_parquet(sample_data, engine="pyarrow")
        print("GOT PARQUET DATA FRAME")
        return df
    except Exception as e:
        print(e)
        raise


def create_parquet_file(file_name: str, data=None):
    """Create local parquet file

    Args:
        file_name (str): File Name to Read
        data (ndarray (structured or homogeneous), Iterable, dict, or DataFrame): the contents of
            the file
    """
    if data is None:

        # sample data
        data = {
            "FirstName": ["Hello1", "Hello2"],
            "LastName": ["World1", "World2"],
            "PhoneNumber": ["123-456-7890", "123-456-7890"],
            "EmailAddress": ["hello1@world.com", "hello2@world.com"],
            "Priority": ["2", "1"],
            "CreateDate": ["2020-04-03 14:00:45", "2022-04-03 14:00:45"],
        }

    df = pd.DataFrame(data)
    df.to_parquet(file_name)
