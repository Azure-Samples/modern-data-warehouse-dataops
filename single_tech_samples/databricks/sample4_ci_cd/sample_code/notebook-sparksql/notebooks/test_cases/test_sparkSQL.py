# Databricks notebook source
# MAGIC  %pip install nutter

# COMMAND ----------
from runtime.nutterfixture import NutterFixture, tag
class MyTestFixture(NutterFixture):
   total = 0
    
   # Arrange
   def before_Records_Exist_Returns_Positive_Number(self):
      dbutils.notebook.run('../sparkSQL_sample', 600)  

   # Act
   def run_Records_Exist_Returns_Positive_Number(self):      
      some_tbl = sqlContext.sql('SELECT TOTAL FROM POPULATION_COUNT LIMIT 1')
      MyTestFixture.total = some_tbl.first()[0]

   #Assert
   def assertion_Records_Exist_Returns_Positive_Number(self):      
      assert (MyTestFixture.total > 0)

   #Clean
   def after_all(self):
       sqlContext.sql('DROP TABLE IF EXISTS  POPULATION_COUNT;')

print("Starting Test")
result = MyTestFixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)

# COMMAND ----------