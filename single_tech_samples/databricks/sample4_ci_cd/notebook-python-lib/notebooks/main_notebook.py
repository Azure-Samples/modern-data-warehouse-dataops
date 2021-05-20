from pyspark.sql import SparkSession
sparkSession = SparkSession.builder.appName("example-pyspark-read-and-write").getOrCreate()
# Create data
data = [('First', 1), ('Second', 2), ('Third', 3), ('Fourth', 4), ('Fifth', 5)]
df = sparkSession.createDataFrame(data)

# Write into HDFS
path = "/opt/test/example.csv"
df.write.mode('overwrite').csv(path)

from common.module_a import int_to_str
print(int_to_str(1000))