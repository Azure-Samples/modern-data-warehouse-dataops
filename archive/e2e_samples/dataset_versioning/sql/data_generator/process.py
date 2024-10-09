import pandas as pd
from datetime import datetime


class Process:
    """Process object to filter df with specified version
    """

    def __init__(self, df: pd.DataFrame, version_date='issue_d'):
        self.version_date = version_date
        self.df = df
        self.min = min(self.df[self.version_date])

    def _version_converter(self, version: int) -> datetime:
        """
        helper function to convert version to timestamp so that it can be processed in sql
        version = 12*(target_year - start_of_year) + (target_month - start_of_month)

        :param version: version of dataset given min datatime is the version 0
        :type version: int
        :return: corresponding datetime
        :rtype: datetime
        """
        months = version + self.min.month + 12 * self.min.year
        year = months // 12
        month = months % 12
        return datetime(year, month, 1, 0, 0)

    def filter_with_version(self, version: int) -> pd.DataFrame:
        """
        Filter dataframe with the version

        :param version: version of dataset given min datatime is the version 0
        :type version: int
        :return: filtered dataframe with the param version
        :rtype: pd.DataFrame
        """

        try:
            return self.df.loc[self.df[self.version_date]
                               == self._version_converter(version)]
        except AttributeError:
            raise
