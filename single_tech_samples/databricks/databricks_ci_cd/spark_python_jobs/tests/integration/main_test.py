
import unittest
import sys

from spark_python_jobs.main import SampleJob
from uuid import uuid4
from pyspark.dbutils import DBUtils  # noqa
from pyspark.sql import SparkSession, DataFrame

class SampleJobIntegrationTest(unittest.TestCase):
    def setUp(self):

        self.test_dir = "dbfs:/tmp/tests/sample/%s" % str(uuid4())
        self.output = self.test_dir 
        self.job = SampleJob()
        self.job.set_output(self.output)
        # self.job.set_spark(SparkSession.builder.getOrCreate())
        self.dbutils = DBUtils(self.job.spark)
        self.job.launch()
        self.df = self.job.spark.read.format("parquet").load(self.output)

    def test_sample_count(self):
        output_count = (
            self.df.count()
        )
        self.assertEqual(output_count, 7)
    

    def test_sample_amount(self):
        amount = self.df.take(1)[0][3]
        self.assertEqual(amount, 10)


    def tearDown(self):
        self.dbutils.fs.rm(self.test_dir, True)


if __name__ == "__main__":
    # please don't change the logic of test result checks here
    # it's intentionally done in this way to comply with jobs run result checks
    # for other tests, please simply replace the SampleJobIntegrationTest with your custom class name
    loader = unittest.TestLoader()
    tests = loader.loadTestsFromTestCase(SampleJobIntegrationTest)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(tests)
    if not result.wasSuccessful():
        raise RuntimeError(
            "One or multiple tests failed. Please check job logs for additional information."
        )