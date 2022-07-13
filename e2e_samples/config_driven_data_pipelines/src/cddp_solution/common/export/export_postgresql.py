from cddp_solution.common.export.export_job import AbstractExportJob
from cddp_solution.common.utils.CddpException import CddpException
from cddp_solution.common.utils.env import getEnv
import psycopg2
from sqlalchemy import create_engine
import urllib.parse


class ExportToPostgreSQL(AbstractExportJob):
    def export(self, df):
        export_postgres_database = urllib.parse.quote_plus(self.config["export_postgres_database"])

        try:
            export_postgres_user = urllib.parse.quote_plus(getEnv(self.config["export_postgres_user_key"]))
            export_postgres_password = urllib.parse.quote_plus(getEnv(self.config["export_postgres_password_key"]))
        except Exception:
            raise CddpException("Please check environment variables for SQL user name and password.")

        export_postgres_host = urllib.parse.quote_plus(self.config["export_postgres_host"])
        export_postgres_schema_name = self.config["export_postgres_schema_name"].lower()
        export_postgres_tablename = self.config["export_postgres_tablename"].lower()
        export_postgres_if_exists = self.config["export_postgres_if_exists"]

        sql_schema_check = 'CREATE SCHEMA IF NOT EXISTS {0};'.format(export_postgres_schema_name)
        # conn_string = 'postgres://user:password@host/data1'
        conn_string = 'postgresql://{0}:{1}@{2}/{3}'.format(export_postgres_user,
                                                            export_postgres_password,
                                                            export_postgres_host,
                                                            export_postgres_database)
        self.export_data_to_postgreSQL(df,
                                       sql_schema_check,
                                       conn_string,
                                       export_postgres_tablename,
                                       export_postgres_schema_name,
                                       export_postgres_if_exists)

    def export_data_to_postgreSQL(self,
                                  df,
                                  sql_schema_check,
                                  conn_string,
                                  export_postgres_tablename,
                                  export_postgres_schema_name,
                                  export_postgres_if_exists):
        # schema
        conn = psycopg2.connect(conn_string)
        conn.autocommit = True
        cursor = conn.cursor()
        cursor.execute(sql_schema_check)
        conn.close()
        # export
        db = create_engine(conn_string)
        conn = db.connect()
        df.to_sql(export_postgres_tablename,
                  con=conn,
                  schema=export_postgres_schema_name,
                  if_exists=export_postgres_if_exists,
                  index=False)
