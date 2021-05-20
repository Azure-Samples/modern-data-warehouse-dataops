import unittest

from src.entrypoint import SampleJob
from uuid import uuid4
from pyspark.dbutils import DBUtils  # noqa

class SampleJobIntegrationTest(unittest.TestCase):
    def setUp(self):

        self.test_dir = "dbfs:/tmp/tests/sample/%s" % str(uuid4())
        self.test_config = {"output_format": "delta", "output_path": self.test_dir}

        self.job = SampleJob(init_conf=self.test_config)
        self.dbutils = DBUtils(self.job.spark)
        self.spark = self.job.spark

    def test_sample(self):

        self.job.launch()

        output_count = (
            self.spark.read.format(self.test_config["output_format"])
            .load(self.test_config["output_path"])
            .count()
        )

        self.assertGreater(output_count, 0)

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