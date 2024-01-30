from pyspark.sql.functions import date_format, col, current_timestamp


def transform(spark, df, config):
    """ This transformation which filter data based on configuration passed

    Args:

    Spark: Spark session
    sourcedf: input file contents in a spark dataframe
    config: JSON config containing tablename, database, date formatting and filter criteria

    returns: dataframe with filter data
    """
    filter_df = df.filter(col(config["key_col"]).isin(config["filter_criteria"]))  # noqa: E501
    return filter_df
