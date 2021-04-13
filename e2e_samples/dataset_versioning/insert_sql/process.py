import pandas as pd
from datetime import datetime


class Process:
    """Process object to filter df with specified version
    """
    def __init__(self, df: pd.DataFrame):
        self.WATER_MARK = 'issue_d'
        self.df = df
        self.min = min(self.df[self.WATER_MARK])

    def _version_converter(self, version: int) -> datetime:
        """
        Convert version to timestamp so that it can be processed in sql.
        version = 12*(target_year - start_of_year) + (target_month - start_of_month)
        """
        months = version + self.min.month + 12 * self.min.year
        year = months // 12
        month = months % 12
        return datetime(year, month, 1, 0, 0)

    def filter_with_version(self, version: int) -> pd.DataFrame:
        return self.df.loc[self.df[self.WATER_MARK] == self._version_converter(version)]
