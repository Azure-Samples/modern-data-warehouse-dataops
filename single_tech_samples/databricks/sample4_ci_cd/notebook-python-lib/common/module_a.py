from pyspark.sql.functions import col, bround, sum as col_sum

# Example case for simple data aggregation:
# Assume there are multiple water pipes each with a unique id (pipe_id)
# and the data contains details of number of liters of water pumped out for a specific duration.
# The module below calculates  the number of litres per second per pipe.

def get_litres_per_second(pipe_data_df):
    output_df = pipe_data_df.withColumn(
        "duration_seconds",
        (
            col("end_time").cast('timestamp').cast('long')
            - col("start_time").cast('timestamp').cast('long')
        )
    ).groupBy("pipe_id").agg(
        col_sum("duration_seconds").alias("total_duration_seconds"),
        col_sum('litres_pumped').alias("total_litres_pumped")
    ).withColumn(
        "avg_litres_per_second",
        bround((col("total_litres_pumped") / col("total_duration_seconds")), 2)
    )
    return output_df
