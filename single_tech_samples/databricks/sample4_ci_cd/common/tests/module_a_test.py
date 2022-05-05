import unittest


from common.module_a import *
from pyspark.sql import SparkSession

class SampleJobUnitTest(unittest.TestCase):
    def setUp(self):

        self.spark = SparkSession.builder.master("local[1]").getOrCreate()
        df = self.spark.createDataFrame([('Fiji Apple', 'Red', 3.5), 
                           ('Banana', 'Yellow', 1.0),
                           ('Green Grape', 'Green', 2.0),
                           ('Red Grape', 'Red', 2.0),
                           ('Peach', 'Yellow', 3.0),
                           ('Orange', 'Orange', 2.0),
                           ('Green Apple', 'Green', 2.5)], 
                           ['Fruit', 'Color', 'Price'])
        self.df = add_mount(df, 20)                   

    def test_sample_amount(self):
        amount = self.df.take(1)[0][3]
        self.assertEqual(amount, 20)



if __name__ == "__main__":
    unittest.main()