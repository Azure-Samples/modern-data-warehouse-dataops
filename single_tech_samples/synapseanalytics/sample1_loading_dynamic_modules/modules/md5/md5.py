from pyspark.sql.functions import concat_ws, md5, date_format, current_timestamp


def transform(spark, sourcedf, config):
    """MD5 transformation which will calcuate MD5 on input data
    
    Args:

    Spark: Spark session
    sourcedf: input file contents in a spark dataframe
    config: JSON config containing tablename, database, date formatting and audit column names

    returns: dataframe with calculated MD5
    """
    df1 = calculate_md5(sourcedf)
    return df1



def calculate_md5(df):
    """Calculate MD5 on all columns of input data frame
    Args:
    df : spark data frame

    returns: dataframe
    """
    col_list = []
    for i in df.columns:
        col_list.append(i)
        resultdf = df.withColumn('md5', md5(concat_ws('_', *col_list)))
    return resultdf