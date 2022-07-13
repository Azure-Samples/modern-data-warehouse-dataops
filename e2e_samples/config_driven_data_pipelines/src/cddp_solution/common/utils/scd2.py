from cddp_solution.common.utils import sink_data_helper
from pathlib import Path
from os.path import exists


def SCD2(spark, df, target_table_path, schema, target_partition_keys_cols, key_cols, current_time):
    """
    Merge newly came data into SCD2 format delta table.

    Parameters
    ----------
    spark : SparkSession
        Spark session

    df : Spark Dataframe
        the newly came data to be merged into target table

    target_table_path : str
        path of the target delta table

    schema: str
        Table schema name

    target_partition_keys_cols: str
        Partition columns

    key_cols: str
        Target columns to generate key hash
        The `key_hash` column is used in SCD2 format to identify data unit which will changes by time


    current_time: datetime
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
        cast('{current_time}' as timestamp)  as dw_insert_ts,
        cast('{current_time}' as timestamp) as dw_update_ts,
        'Y' as row_latest_ind,
        cast('{current_time}' as timestamp)  as row_active_start_ts,
        cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as row_active_end_ts
        from {output_view_name} a """

        data = spark.sql(sql)

        sink_data_helper.save_as_delta_table(data,
                                             target_table_path,
                                             f"{schema}.{Path(target_table_path).name}",
                                             partition_keys=target_partition_keys_cols)

        return data
    else:
        target_table_name = "target_data_view"
        target_data = spark.read.format("delta").load(target_table_path)
        # target_data.show()
        target_data.createOrReplaceTempView(target_table_name)

        insert_col = "row_latest_ind, row_active_start_ts, row_active_end_ts, dw_insert_ts, dw_update_ts, " + \
                     (",".join(keyhash_col)) + \
                     "," + (",".join(datahash_col)) + ",key_hash, data_hash"
        insert_col_values = "b."+(", b.".join(keyhash_col))+", b."+(", b.".join(datahash_col))+""
        insert_values = f"""
            'Y' as row_latest_ind,
            cast('{current_time}' as timestamp)  as row_active_start_ts ,
            cast('9999-12-31 00:00:00.000000+00:00' as timestamp) as row_active_end_ts,
        cast('{current_time}' as timestamp)  as dw_insert_ts,
        cast('{current_time}' as timestamp) as dw_update_ts,
            {insert_col_values},
            b.key_hash as key_hash,
            b.data_hash as data_hash"""

        update_col_values = "a."+(", a.".join(keyhash_col))+", a."+(", a.".join(datahash_col))+""
        update_values = f"""
        CASE WHEN a.data_hash <> b.data_hash THEN 'N' ELSE a.row_latest_ind END as row_latest_ind,
        a.row_active_start_ts ,
        CASE WHEN a.data_hash <> b.data_hash THEN cast('{current_time}' as timestamp)
        ELSE a.row_active_end_ts END as row_active_end_ts,
        a.dw_insert_ts,
        CASE WHEN a.data_hash <> b.data_hash THEN cast('{current_time}' as timestamp)
        ELSE a.dw_update_ts  END as dw_update_ts,
        {update_col_values},
        a.key_hash as key_hash,
        a.data_hash as data_hash
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
        LEFT OUTER JOIN {staged_updates_1} b
        ON a.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash AND a.row_latest_ind = 'Y'
        """

        sql2 = f"""
        SELECT
        {insert_values}
        FROM {staged_updates_1} b
        INNER JOIN {target_table_name} a
        ON a.key_hash = b.mergeKey0 AND a.data_hash<>b.data_hash AND a.row_latest_ind = 'Y'
        """

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

        sink_data_helper.save_as_delta_table(data,
                                             target_table_path,
                                             f"{schema}.{Path(target_table_path).name}",
                                             partition_keys=target_partition_keys_cols)

        return data
