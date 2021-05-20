from pyspark.sql.functions import col, sum as col_sum


def get_litres_per_second(pump_data_df):
    output_df = pump_data_df.withColumn(
        "duration_seconds",
        (
            col("end_time").cast('timestamp').cast('long')
            - col("start_time").cast('timestamp').cast('long')
        )
    ).groupBy("pump_id").agg(
        col_sum("duration_seconds").alias("total_duration_seconds"),
        col_sum('litres_pumped').alias("total_litres_pumped")
    ).withColumn(
        "avg_litres_per_second",
        col("total_litres_pumped") / col("total_duration_seconds")
    )
    return output_df
