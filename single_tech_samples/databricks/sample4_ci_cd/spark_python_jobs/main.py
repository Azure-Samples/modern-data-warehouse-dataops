from pyspark.sql import SparkSession, DataFrame
from pyspark.sql import functions as F
from common.module_a import add_mount

class SampleJob():

    def __init__(self, spark=None):
        self.spark = spark
        if not self.spark:
            self.spark = SparkSession.builder.getOrCreate()

    def double_price(self, df: DataFrame):
        return df.select('Fruit', 'Color', (F.col('Price') * 2).alias('Price'))

    def set_output(self, path):
        self.output = path

    def transform_data(self, df: DataFrame): 
        df = self.double_price(df)
        df = add_mount(df, 10)
        return df

    def launch(self):
        df = self.spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])
        df = self.transform_data(df)
        df.write.format("parquet").mode("overwrite").save(self.output)

if __name__ == "__main__":
    job = SampleJob()
    job.launch()
