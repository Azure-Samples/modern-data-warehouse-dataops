import pandas as pd
from pathlib import Path


def parquet2csv(in_path, out_path):
    """
    Transfer parquest format file into csv format file.

    Parameters
    ----------
    in_path : str
        file path of source parquet format file

    out_path : str
        file path of target csv format file

    """
    data = pd.read_parquet(in_path)
    filepath = Path(out_path)
    filepath.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(filepath)
