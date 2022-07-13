

def save_as_delta_table(data, table_path, table_name, mode="append", partition_keys=None):
    """ Sink data as external delta table

    Parameters
    ----------
    data: data_frame
        Target data that will sink to delta table

    table_path: string
        Target path to sink the data

    table_name: string
        Table name with or without schema prefix
    mode: string
        Default is append, overwrite is an user input
    partition_keys: string
        Partition keys, optional
    """

    if not partition_keys:
        data.write.format("delta")\
            .mode(mode)\
            .option("path", table_path)\
            .saveAsTable(table_name)
    else:
        partition_keys = get_partition_keys(data, partition_keys)
        data.write.format("delta")\
            .mode(mode)\
            .partitionBy(partition_keys)\
            .option("path", table_path)\
            .saveAsTable(table_name)


def save_as_streaming_delta_table(data, table_path, table_checkpoint_path, table_name, partition_keys=None):
    """
    Sink data as external streaming delta table

    Parameters
    ----------
    data: dataframe
        Target data that will sink to delta table

    table_path: str
        Target path to sink the data
    table_checkpoint_path: string
        Path to store check pointing info
    table_name: string
        Table name with or without schema prefix

    partition_keys: str
        Partition keys, optional


    Returns
    ----------
    streaming query
    """

    if not partition_keys:
        streaming_query = data.writeStream\
                              .format("delta") \
                              .outputMode("append")\
                              .option("path", table_path)\
                              .option("checkpointLocation", table_checkpoint_path)\
                              .toTable(table_name)
    else:
        partition_keys = get_partition_keys(data, partition_keys)
        streaming_query = data.writeStream\
                              .format("delta") \
                              .outputMode("append")\
                              .option("path", table_path)\
                              .option("checkpointLocation", table_checkpoint_path)\
                              .partitionBy(partition_keys)\
                              .toTable(table_name)

    return streaming_query


def get_partition_keys(df, partition_keys):
    """
    Get partition keys array from partition keys string, excluding those not in available columns

    Parameters
    ----------
    df : dataframe
        Target dataframe, which is used to determine all available columns

    partition_keys : str
        Partition keys defined in config.json file

    Returns
    ----------
    array
        Parttion keys array
    """
    columns = [col for col in df.columns]
    strip_partition_keys = [key.strip() for key in partition_keys.split(",")]

    return [col for col in columns if col in strip_partition_keys]
