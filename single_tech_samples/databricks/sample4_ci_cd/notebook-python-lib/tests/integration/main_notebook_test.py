from pyspark.sql import SparkSession
from runtime.nutterfixture import NutterFixture, tag

class MyTestFixture(NutterFixture):
   def run_test_name(self):
      dbutils.notebook.run('../../notebooks/main_notebook', 600)

   def assertion_test_name(self):
      sparkSession = SparkSession.builder.appName("example-pyspark-read").getOrCreate()
      # Create data
      # df = sparkSession.createDataFrame(data)
      path = "/opt/test/example.csv"

      # Read from HDFS
      df_load = sparkSession.read.csv(path)
      df_load.show()
      assert (df_load.count() == 5)
      #assert (1==1)

result = MyTestFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)