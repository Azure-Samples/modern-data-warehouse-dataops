from cddp_solution.common.utils import sink_data_helper
from pathlib import Path
from os.path import exists
import pyspark.sql.functions as f


def merge_to_scd2(spark,
                  df,
                  target_table_path,
                  schema,
                  target_partition_keys_cols,
                  key_cols,
                  current_time,
                  save_to_ts_col=True,
                  save_is_active_col=True,
                  from_ts_col_name="row_active_start_ts",
                  to_ts_col_name="row_active_end_ts",
                  is_active_col_name="Is_active"):
    """
    Merge newly came data into SCD2 format delta table.
    Similar to `cddp_solution.common.utils.SCD2` but able to handle target table which does not have "end" column.

    Parameters
    ----------
    spark : SparkSession
        Spark session

    df : Spark Dataframe
        the newly came data to be merged into target table

    target_table_path : str
        path of the target delta table

    schema : str
        schema name of the table

    target_partition_keys_cols : array
        partition keys used when saving target table

    key_cols : array
        target columns to generate `key_hash`. Can be multiple.
        The `key_hash` column is used in SCD2 format to identify data unit which will changes by time

    current_time : datetime
        timestamp of current

    save_to_ts_col : bool
        - True: save scd2 with an effective end to timestamp column "end"
        - False: not save with effective end,
        by default True

    save_is_active_col : bool
        - True: save scd2 with a column "Y/N" showing if the row is the latest(active) data
        - False: not save
        by default True

    from_ts_col_name : str
        column name for effective start column, by default "row_active_start_ts"
        The "start" column is used in SCD2 to mark the time when the change came in

    to_ts_col_name : str
        column name for effective end column, by default "row_active_end_ts"
        The "end" column is used in SCD2 to mark the time when the change became invalid

    is_active_col_name : str
        column name for is_active column, by default "Is_active"


    Returns
    ----------
    Spark Dataframe
        merged data result
    """

    # create a temp view
    input_view_name = 'INPUT_VIEW'
    df.createOrReplaceTempView(input_view_name)

    # deal with columns
    col = [x.upper() for x in df.columns]
    datahash_col = [x for x in col if x not in set(key_cols.upper().split(","))]
    keyhash_col = [x for x in col if x in set(key_cols.upper().split(","))]

    # create a view with key_hash and data_hash
    sql = f"""
    select a.*,
        md5(concat(COALESCE( {",''), COALESCE(".join(keyhash_col)} ,''))) as key_hash,
        md5(concat(COALESCE( {",''), COALESCE(".join(datahash_col)} ,''))) as data_hash
        from {input_view_name} a
    """

    out_df = spark.sql(sql)
    output_view_name = 'OUTPUT_VIEW'
    out_df.createOrReplaceTempView(output_view_name)

    target_partition_keys_cols = target_partition_keys_cols.upper()

    if not exists(target_table_path):
        insert_col_values = "a."+(", a.".join(keyhash_col))+", a."+(", a.".join(datahash_col))+""

        sql = f"""

        select {insert_col_values},
        a.key_hash,
        a.data_hash,
        cast('{current_time}' as timestamp)  as {from_ts_col_name},
        cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as {to_ts_col_name},
        'Y' as {is_active_col_name}
        from {output_view_name} a """
        # print(sql)

        data = spark.sql(sql)

        # drop unused columns
        data = data.drop('data_hash')
        if not save_to_ts_col:
            data = data.drop(to_ts_col_name)
        if not save_is_active_col:
            data = data.drop(is_active_col_name)
        # print(data.show())

        sink_data_helper.save_as_delta_table(data,
                                             target_table_path,
                                             f"{schema}.{Path(target_table_path).name}",
                                             "overwrite",
                                             partition_keys=target_partition_keys_cols)

        return data
    else:
        # original target table
        target_original_table_name = "target_original_data_view"
        target_original_data = spark.read.format("delta").load(target_table_path)
        target_original_data.createOrReplaceTempView(target_original_table_name)

        # target table = originial target table + data_hash
        sql = f"""
            select a.*,
                md5(concat(COALESCE( {",''), COALESCE(".join(datahash_col)} ,''))) as data_hash
                from {target_original_table_name} a
            """

        target_table_name = "target_data_view"
        target_data = spark.sql(sql)
        # print(target_data.show())

        # if row_active_end_ts not existing, implement with null value
        if to_ts_col_name not in target_data.columns:
            target_data = target_data.withColumn(to_ts_col_name, f.lit(None))
        if is_active_col_name not in target_data.columns:
            target_data = target_data.withColumn(is_active_col_name, f.lit(None))

        # print(target_data.show())
        target_data.createOrReplaceTempView(target_table_name)

        target_latest = f""" SELECT
                key_hash,
                MAX({from_ts_col_name}) as {from_ts_col_name}
            FROM
                {target_table_name}
            GROUP BY key_hash
        """
        # print(spark.sql(target_latest).show())

        insert_col = f"{is_active_col_name}, {from_ts_col_name}, {to_ts_col_name}, " +\
                     (",".join(keyhash_col)) + "," + (",".join(datahash_col))+",key_hash"
        insert_col_values = "b."+(", b.".join(keyhash_col))+", b."+(", b.".join(datahash_col))+""
        insert_values = f"""
            'Y' as {is_active_col_name},
            cast('{current_time}' as timestamp)  as {from_ts_col_name} ,
            cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as {to_ts_col_name},
            {insert_col_values},
            b.key_hash as key_hash"""

        update_col_values = "a."+(", a.".join(keyhash_col))+", a."+(", a.".join(datahash_col))+""
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

        sql1 = f"""
        SELECT
        {update_values}
        FROM {target_table_name} a
        LEFT OUTER JOIN ({target_latest}) a2
        on a.key_hash = a2.key_hash and a.{from_ts_col_name} = a2.{from_ts_col_name}
        LEFT OUTER JOIN {staged_updates_1} b
        ON a2.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash
        """
        # print(sql1)
        # spark.sql(sql1).show()

        sql2 = f"""
        SELECT
        {insert_values}
        FROM {staged_updates_1} b
        INNER JOIN {target_table_name} a
        ON a.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash
        INNER JOIN ({target_latest}) a2
        ON a.key_hash = a2.key_hash AND a.{from_ts_col_name} = a2.{from_ts_col_name}
        """
        # print(sql2)
        # spark.sql(sql2).show()

        sql3 = f"""
        SELECT {insert_col} FROM (
        SELECT
        {insert_values}, a.key_hash as a_key_hash
        FROM {staged_updates_1} b
        LEFT OUTER JOIN {target_table_name} a
        ON a.key_hash = b.mergeKey0
        )
        WHERE a_key_hash is null
        """
        # print(sql3)
        # spark.sql(sql3).show()

        sql = f"""
        SELECT DISTINCT * FROM (
        {sql1}
        UNION ALL
        {sql2}
        UNION ALL
        {sql3}
        )
        """

        data = spark.sql(sql)
        if not save_to_ts_col:
            data = data.drop(to_ts_col_name)
        if not save_is_active_col:
            data = data.drop(is_active_col_name)
        # print(data.show())

        sink_data_helper.save_as_delta_table(data,
                                             target_table_path,
                                             f"{schema}.{Path(target_table_path).name}",
                                             partition_keys=target_partition_keys_cols)
        return data
