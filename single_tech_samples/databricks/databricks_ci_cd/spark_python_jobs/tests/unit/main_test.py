import unittest
import tempfile
import os
import shutil



from spark_python_jobs.main import SampleJob
from pyspark.sql import SparkSession
from unittest.mock import MagicMock
from pyspark.sql import functions as F

class SampleJobUnitTest(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.TemporaryDirectory().name
        self.output = os.path.join(self.test_dir, "output")
        self.spark = SparkSession.builder.master("local[1]").getOrCreate()
        self.job = SampleJob(self.spark)
        # self.job.set_spark(self.spark)
        self.job.set_output(self.output)
        self.job.launch()
        self.df = self.spark.read.format("parquet").load(self.output)

    def test_sample_count(self):
        output_count = (
            self.df.count()
        )
        self.assertEqual(output_count, 7)
    
    def test_sample_price(self):
        price = self.df.take(1)[0][2]
        self.assertEqual(price, 7)

    def test_sample_amount(self):
        amount = self.df.take(1)[0][3]
        self.assertEqual(amount, 10)

    def tearDown(self):
        shutil.rmtree(self.output)


if __name__ == "__main__":
    unittest.main()