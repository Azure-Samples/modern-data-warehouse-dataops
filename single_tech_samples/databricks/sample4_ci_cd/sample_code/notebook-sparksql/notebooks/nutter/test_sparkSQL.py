# Databricks notebook source
# MAGIC  %pip install nutter

# COMMAND ----------
from runtime.nutterfixture import NutterFixture, tag
class MyTestFixture(NutterFixture):

   # Arrange
   def before_test_Records_Exist_Returns_Positive_Number(self):
      self.code1_result = dbutils.notebook.run('./testSQL', 600)  

   # Act
   def run_test_Records_Exist_Returns_Positive_Number(self):
      some_tbl = sqlContext.sql('SELECT TOTAL FROM POPULATION_COUNT LIMIT 1')

   #Assert
   def assertion_Records_Exist_Returns_Positive_Number(self):      
      assert (some_tbl.first()[0] > 1)

   #Clean
   def after_all(self):
       sqlContext.sql('DROP TABLE POPULATION_COUNT')

print("Starting Test")
result = MyTestFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)

# COMMAND ----------