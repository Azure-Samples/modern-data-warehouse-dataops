from keyvault_wrapper import KeyvaultWrapper
import pandas as pd
from sqlalchemy import text, create_engine


class SqlWrapper:
    def __init__(self, kv: KeyvaultWrapper):
        self.engine = create_engine(
            f'mssql+pymssql://{kv.user_name}:{kv.password}@{kv.server}/{kv.database}')
        self.table_name = kv.table_name

    def insert_to_sql(self, df: pd.DataFrame):
        df.to_sql(
            self.table_name,
            con=self.engine,
            if_exists='append',
            index=False)

    def _truncate_table(self):
        connection = self.engine.connect()
        truncate_query = text("TRUNCATE TABLE " + self.table_name)
        connection.execution_options(autocommit=True).execute(truncate_query)

    def _remove_deltalake(self):
        pass

    def clean_up(self):
        self._truncate_table()
        self._remove_deltalake()
