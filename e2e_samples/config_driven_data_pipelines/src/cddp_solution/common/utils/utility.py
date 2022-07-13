from cddp_solution.common.utils.spark_job import AbstractSparkJob
from cddp_solution.common.utils import sink_data_helper
from cddp_solution.common.utils import env
from cddp_solution.common.utils.DataProcessingPhase import DataProcessingPhase
from pathlib import Path
from pyspark.sql import functions as F
import logging
import inspect
import os


class utility():
    def __init__(self, config):
        self.spark_job_obj = AbstractSparkJob(config)

        self.config = config

    def get_latest_file_from_folder(self, source_table_name, location):
        """ Identify the latest file in the Landing Zone
            Parameters
            ----------
            source_table_name: Source Table Name
        """

        self.spark_job_obj.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        source_path = f"{self.spark_job_obj.landing_data_storage_path}/{source_table_name}"

        if env.isRunningOnDatabricks():
            if str(source_path).startswith("/mnt/"):
                source_path = f"/dbfs{source_path}"
        else:
            resources_base_path = self.config["resources_base_path"]
            source_system = self.config["domain"]
            source_path = Path(resources_base_path, f"{source_system}_customers", location).as_posix()

        self.spark_job_obj.logger.log(logging.INFO, f"Landing zone source path: {source_path}")

        file_modified_date = 0
        latest_file = None
        for dirpath, sub_dirs, filenames in os.walk(source_path):
            for file in filenames:
                fdpath = os.path.abspath(os.path.join(dirpath, file))
                stat_info = os.stat(fdpath)
                if stat_info.st_mtime > file_modified_date:
                    file_modified_date = stat_info.st_mtime
                    latest_file = fdpath

        self.spark_job_obj.logger.log(logging.INFO, f"Landing zone latest file: {latest_file}")

        self.spark_job_obj.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return latest_file

    def transform_md5(self, source_df, data_source):
        """ Apply MD5 Logic and get the delta rows

        Parameters
        ----------
        source_df: dataframe
            New data from landing zone
        data_source: dictionary
            Customer configuration json file
        """

        self.spark_job_obj.logger.log(logging.INFO, f"## Job Started: {inspect.currentframe().f_code.co_name}")

        target_tablename = data_source["table_name"]
        partition_keys = data_source["partition_keys"]

        col_md5 = self.spark_job_obj.audit_cols["rz_master"]["md5"]

        target_table_path = f"{self.spark_job_obj.staging_data_storage_path}/{target_tablename}"

        db_tablename = f"{self.spark_job_obj.rz_dbname}.{target_tablename}"
        self.spark_job_obj.logger.log(logging.INFO, f"db_tablename: {db_tablename}")

        # Generate md5 column
        col_list = source_df.columns
        source_md5_df = source_df.withColumn(col_md5, F.md5(F.concat_ws('_', *col_list)))

        # Add audit columns
        source_md5_df = self.spark_job_obj.add_audit_columns(source_md5_df,
                                                             DataProcessingPhase.MASTER_LANDING_TO_STAGING)

        spark_tables = self.spark_job_obj.spark.catalog.listTables(self.spark_job_obj.rz_dbname)
        is_table_exists = any(x.database == self.spark_job_obj.rz_dbname.lower() and
                              x.name == target_tablename.lower() for x in spark_tables)
        self.spark_job_obj.logger.log(logging.INFO, f"is_table_exists '{target_tablename}': {is_table_exists}")

        if not (is_table_exists):
            # Table Not Exist (First Run) = Overwrite
            self.spark_job_obj.logger.log(logging.INFO, "Staging zone First run")
            _ = sink_data_helper.save_as_delta_table(source_md5_df,
                                                     target_table_path,
                                                     db_tablename,
                                                     "overwrite",
                                                     partition_keys)
            self.spark_job_obj.logger.log(logging.INFO, f"Target Table '{target_table_path}' updated with new data")

        else:
            self.spark_job_obj.logger.log(logging.INFO,
                                          f"Target Table '{target_table_path}' already exists in the Staging zone")

            try:
                raw_existing_df = self.spark_job_obj.spark.sql(f"select * from {db_tablename}")
            except Exception as E:
                self.spark_job_obj.logger.log(logging.ERROR,
                                              ("Error while loading data from existing "
                                               f"delta table: {db_tablename}\n{E}"))

                # Table Exist but Delta files NOT Exist = Overwrite
                self.spark_job_obj.logger.log(logging.INFO, "Staging zone overwrite as files / folder does NOT exist")
                _ = sink_data_helper.save_as_delta_table(source_md5_df,
                                                         target_table_path,
                                                         db_tablename,
                                                         "overwrite",
                                                         partition_keys)
                self.spark_job_obj.logger.log(logging.INFO,
                                              f"Target Table '{target_table_path}' updated with new data")

                return

            # Table Exist and Delta files Exist = Append

            # TODO: Try with Left ANTI join
            delta_df = (source_md5_df.select(col_md5).subtract(raw_existing_df.select(col_md5)))
            delta_rows_count = delta_df.count()
            if delta_rows_count > 0:
                self.spark_job_obj.logger.log(logging.INFO, f"Total no. of delta rows found: {delta_rows_count}")
                delta_df = source_md5_df.join(delta_df, [col_md5], 'inner')
                final_df = delta_df.select(raw_existing_df.columns)

                _ = sink_data_helper.save_as_delta_table(final_df,
                                                         target_table_path,
                                                         db_tablename,
                                                         "append",
                                                         partition_keys)
                self.spark_job_obj.logger.log(logging.INFO,
                                              (f"Target Table '{target_table_path}' updated with new "
                                               f"rows {delta_rows_count} in the Staging zone"))
            else:
                self.spark_job_obj.logger.log(logging.INFO, "NO new delta rows identified from the source data")

        self.spark_job_obj.logger.log(logging.INFO, f"## Job Ended: {inspect.currentframe().f_code.co_name}")
        return

    def merge_to_scd2(self,
                      raw_data,
                      target_table_path,
                      target_tablename,
                      schema,
                      target_partition_keys_cols,
                      key_cols,
                      current_time,
                      from_ts_col_name="row_active_start_ts",
                      to_ts_col_name="row_active_end_ts",
                      is_active_col_name="Is_active"):
        """
            Merge newly came data into SCD2 format delta table.
            Similar to `cddp_solution.common.utils.SCD2` but able to handle target
            table which does not have "end" column.

            Parameters
            ----------
            raw_data: dataframe

            target_table_path : str
                path of the target delta table

            target_tablename : str

            schema : str
                schema name of the table

            target_partition_keys_cols : array
                partition keys used when saving target table

            key_cols : array
                target columns to generate `key_hash`. Can be multiple.
                The `key_hash` column is used in SCD2 format to identify data unit which will changes by time

            current_time : datetime
                timestamp of current

            from_ts_col_name : str
                column name for effective start column, by default "row_active_start_ts"
                The "start" column is used in SCD2 to mark the time when the change came in

            to_ts_col_name : str
                column name for effective end column, by default "row_active_end_ts"
                The "end" column is used in SCD2 to mark the time when the change became invalid

            is_active_col_name : str
                column name for is_active column, by default "Is_active"

        """

        self.spark_job_obj.logger.log(logging.INFO, f"## Job {inspect.currentframe().f_code.co_name} started")
        rz_create_ts = self.spark_job_obj.audit_cols["rz_master"]["create_ts"]

        if target_partition_keys_cols:
            target_partition_keys_cols = target_partition_keys_cols.upper()
        else:
            target_partition_keys_cols = None

        spark_tables = self.spark_job_obj.spark.catalog.listTables(self.spark_job_obj.pz_dbname)
        is_table_exists = any(x.database == self.spark_job_obj.pz_dbname.lower() and
                              x.name == target_tablename.lower() for x in spark_tables)
        self.spark_job_obj.logger.log(logging.INFO, f"is_table_exists '{target_tablename}': {is_table_exists}")

        if not (is_table_exists):
            # Table Not Exist (First Run)
            self.spark_job_obj.logger.log(logging.INFO,
                                          (f"Table {target_tablename} Not Exist in Standard zone "
                                           f"(First Run : Overwrite) | Table path: {target_table_path}"))

        else:
            self.spark_job_obj.logger.log(logging.INFO,
                                          f"Target Table exist {target_tablename} | Path: {target_table_path}")

            try:
                # Target table of Standard zone exist and create temporary view of it
                self.spark_job_obj.load_storage_to_tempview(os.path.dirname(target_table_path), target_tablename)
            except Exception as E:
                # Table Exist but Delta files NOT Exist
                self.spark_job_obj.logger.log(logging.ERROR,
                                              ("Error while loading data from existing delta "
                                               f"table: {target_tablename}\n{E}"))
                is_table_exists = False
            else:
                # Table Exist and Delta files Exist
                try:
                    pz_max_ts = self.spark_job_obj.spark.sql(f"SELECT MAX({rz_create_ts}) FROM {target_tablename}")\
                                                        .collect()[0][0]
                except Exception as E:
                    self.spark_job_obj.logger.log(logging.ERROR,
                                                  (f"Error while getting max value of {rz_create_ts} from "
                                                   f"table {target_tablename}\n{E}"))
                    pz_max_ts = None

                self.spark_job_obj.logger.log(logging.INFO, f"Latest value of {rz_create_ts}: {pz_max_ts}")
                if pz_max_ts:
                    # Get delta records
                    raw_data = raw_data.filter(raw_data[rz_create_ts] > pz_max_ts)

                    # This check is needed to exit if no delta rows
                    delta_rows_count = raw_data.count()
                    if delta_rows_count == 0:
                        self.spark_job_obj.logger.log(logging.INFO,
                                                      "NO new delta rows identified from the staging data")
                        self.spark_job_obj.logger.log(logging.INFO,
                                                      f"## Job {inspect.currentframe().f_code.co_name} ended")
                        return
                    else:
                        self.spark_job_obj.logger.log(logging.INFO, f"Delta rows count: {delta_rows_count}")

        self.spark_job_obj.logger.log(logging.INFO, "SCD2 Logic implementation")

        # Create a input view with key_hash and data_hash
        input_view_name = 'INPUT_VIEW'
        raw_data.createOrReplaceTempView(input_view_name)

        # Deal with columns
        col = [x.upper() for x in raw_data.columns]
        keyhash_col = [x for x in col if x in set(key_cols.upper().split(","))]

        # Do NOT convert audit columns to uppercase otherwise we would face duplicated column issues
        # while adding audit fields
        audit_cols = list(self.spark_job_obj.audit_cols["rz_master"].values())
        except_audit_cols = [x.upper() for x in raw_data.columns if x not in audit_cols]

        datahash_col = [x for x in except_audit_cols if x not in set(key_cols.upper().split(","))] + audit_cols
        datahash_col_str = [f"CAST ({x} AS STRING)" for x in datahash_col]

        sql = f"""
            select a.*,
                md5(concat(COALESCE( {",''), COALESCE(".join(keyhash_col)} ,''))) as key_hash,
                md5(concat(COALESCE( {",''), COALESCE(".join(datahash_col_str)} ,''))) as data_hash
                from {input_view_name} a
            """

        out_df = self.spark_job_obj.spark.sql(sql)

        # Create a output view with key_hash and data_hash
        output_view_name = 'OUTPUT_VIEW'
        out_df.createOrReplaceTempView(output_view_name)

        db_tablename = f"{schema}.{target_tablename}"

        # Table Not Exist (First Run)
        if not (is_table_exists):
            self.spark_job_obj.logger.log(logging.INFO, f"SCD2 processing of target table {db_tablename} - First run")

            insert_col_values = "a." + (", a.".join(keyhash_col)) + ", a." + (", a.".join(datahash_col)) + ""

            sql = f"""
                select {insert_col_values},
                a.key_hash,
                a.data_hash,
                cast('{current_time}' as timestamp)  as {from_ts_col_name},
                cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as {to_ts_col_name},
                'Y' as {is_active_col_name}
                from {output_view_name} a """

            data = self.spark_job_obj.spark.sql(sql)

            # Drop unused columns
            data = data.drop('data_hash')

            # Add audit columns
            data = self.spark_job_obj.add_audit_columns(data, DataProcessingPhase.MASTER_STAGING_TO_STANDARD)

            sink_data_helper.save_as_delta_table(data,
                                                 target_table_path,
                                                 db_tablename,
                                                 "overwrite",
                                                 partition_keys=target_partition_keys_cols)

            self.spark_job_obj.logger.log(logging.INFO,
                                          f"Target table {db_tablename} updated, Table path: {target_table_path}")

        # For delta rows
        else:
            self.spark_job_obj.logger.log(logging.INFO, f"Target table {db_tablename} - other run")
            # original target table
            target_original_temp_view = "target_original_data_view"
            target_original_data = self.spark_job_obj.spark.read.format("delta").load(target_table_path)
            target_original_data.createOrReplaceTempView(target_original_temp_view)

            # Target table = original target table + data_hash
            sql = f"""
                select a.*,
                    md5(concat(COALESCE( {",''), COALESCE(".join(datahash_col_str)} ,''))) as data_hash
                    from {target_original_temp_view} a
                """

            target_temp_view = "target_data_view"
            target_data_hash = self.spark_job_obj.spark.sql(sql)

            # if row_active_end_ts not existing, implement with null value
            if to_ts_col_name not in target_data_hash.columns:
                target_data_hash = target_data_hash.withColumn(to_ts_col_name, F.lit(None))

            if is_active_col_name not in target_data_hash.columns:
                target_data_hash = target_data_hash.withColumn(is_active_col_name, F.lit(None))

            target_data_hash.createOrReplaceTempView(target_temp_view)

            # target latest = latest rows of target table
            target_latest = f"""SELECT
                    key_hash,
                    MAX({from_ts_col_name}) as {from_ts_col_name}
                FROM
                    {target_temp_view}
                GROUP BY key_hash
            """

            insert_col = f"{is_active_col_name}, {from_ts_col_name}, {to_ts_col_name}, " +\
                         (",".join(keyhash_col)) + "," + (",".join(datahash_col)) + ",key_hash"
            insert_col_values = "b." + (", b.".join(keyhash_col)) + ", b." + (", b.".join(datahash_col)) + ""
            insert_values = f"""
            'Y' as {is_active_col_name},
            cast('{current_time}' as timestamp)  as {from_ts_col_name} ,
            cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as {to_ts_col_name},
            {insert_col_values},
            b.key_hash as key_hash"""

            update_col_values = "a." + (", a.".join(keyhash_col)) + ", a." + (", a.".join(datahash_col)) + ""
            update_values = f"""
            CASE WHEN a.data_hash <> b.data_hash THEN 'N' ELSE a.{is_active_col_name} END as {is_active_col_name},
            a.{from_ts_col_name} ,
            CASE WHEN a.data_hash <> b.data_hash THEN cast('{current_time}' as timestamp)
            ELSE a.{to_ts_col_name} END as {to_ts_col_name},
            {update_col_values},
            a.key_hash as key_hash
            """

            staged_updates_1 = f""" (
            SELECT {output_view_name}.key_hash as mergeKey0, {output_view_name}.*
            FROM {output_view_name}
            )
            """

            """
            For data already existing (key_hash existing) in the target table:
            - if there is no new value coming in, remain same
            - if there is new value coming in, update "is_active" to "N" and "row_active_end_ts" to current time
            """

            sql1 = f"""
            SELECT
            {update_values}
            FROM {target_temp_view} a
            LEFT OUTER JOIN ({target_latest}) a2
            on a.key_hash = a2.key_hash and a.{from_ts_col_name} = a2.{from_ts_col_name}
            LEFT OUTER JOIN {staged_updates_1} b
            ON a2.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash
            """

            """
            For data already existing (key_hash existing) in the target table and having new values coming in:
            - insert the new values
            """

            sql2 = f"""
            SELECT
            {insert_values}
            FROM {staged_updates_1} b
            INNER JOIN {target_temp_view} a
            ON a.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash
            INNER JOIN ({target_latest}) a2
            ON a.key_hash = a2.key_hash AND a.{from_ts_col_name} = a2.{from_ts_col_name}
            """

            """
            For data newly coming in yet not existing (key_hash not existing) in the target table:
            - insert the new data
            """

            sql3 = f"""
            SELECT {insert_col} FROM (
            SELECT
            {insert_values}, a.key_hash as a_key_hash
            FROM {staged_updates_1} b
            LEFT OUTER JOIN {target_temp_view} a
            ON a.key_hash = b.mergeKey0
            )
            WHERE a_key_hash is null
            """

            sql = f"""
            SELECT DISTINCT * FROM (
            {sql1}
            UNION ALL
            {sql2}
            UNION ALL
            {sql3}
            )
            """

            data = self.spark_job_obj.spark.sql(sql)

            # Add audit columns
            data = self.spark_job_obj.add_audit_columns(data, DataProcessingPhase.MASTER_STAGING_TO_STANDARD)

            sink_data_helper.save_as_delta_table(data,
                                                 target_table_path,
                                                 db_tablename,
                                                 "overwrite",
                                                 partition_keys=target_partition_keys_cols)

            self.spark_job_obj.logger.log(logging.INFO,
                                          f"Target table {db_tablename} updated, Table path: {target_table_path}")
        self.spark_job_obj.logger.log(logging.INFO, f"## Job {inspect.currentframe().f_code.co_name} ended")
