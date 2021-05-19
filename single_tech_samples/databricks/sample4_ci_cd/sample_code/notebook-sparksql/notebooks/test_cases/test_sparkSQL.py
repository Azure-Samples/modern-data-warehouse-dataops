# Databricks notebook source
# MAGIC  %pip install nutter

# COMMAND ----------
from runtime.nutterfixture import NutterFixture, tag
class MyTestFixture(NutterFixture):
   total = 0
   first_year = 0
    
   # Arrange
   def before_all(self):
      dbutils.notebook.run('../sparkSQL_sample', 600)  

   # ************** Test Case 1 ********************
   # Act
   def run_Records_Exist_Returns_Positive_Number(self):      
      temp_result = sqlContext.sql('SELECT TOTAL FROM POPULATION_COUNT LIMIT 1')
      MyTestFixture.total = temp_result.first()[0]

   #Assert
   def assertion_Records_Exist_Returns_Positive_Number(self):      
      assert (MyTestFixture.total > 0)

   #Clean
   def after_Records_Exist_Returns_Positive_Number(self):
       sqlContext.sql('DROP TABLE IF EXISTS POPULATION_COUNT;')

   # ************** Test Case 2 ********************
   # Act
   def run_FIRST_YEAR_RETURNS_1960(self):      
      temp_result = sqlContext.sql('SELECT YEAR FROM FIRST_YEARS_PUPULATION LIMIT 1')
      MyTestFixture.first_year = temp_result.first()[0]

   #Assert
   def assertion_FIRST_YEAR_RETURNS_1960(self):      
      assert (MyTestFixture.first_year == 1960)

   #Clean
   def after_FIRST_YEAR_RETURNS_1960(self):
       sqlContext.sql('DROP TABLE IF EXISTS FIRST_YEARS_PUPULATION;')

print("Starting Nutter tests")
result = MyTestFixture().execute_tests()
print("Test execution complete")
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)

# COMMAND ----------