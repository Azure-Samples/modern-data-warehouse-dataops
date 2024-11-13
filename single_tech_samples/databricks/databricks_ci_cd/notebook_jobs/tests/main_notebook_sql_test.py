# Databricks notebook source
# MAGIC %pip install nutter

# COMMAND ----------

from runtime.nutterfixture import NutterFixture, tag
class Test1Fixture(NutterFixture):
   total = 0
   first_year = 0
    
   # Arrange All
   def before_all(self):
      sqlContext.sql('CREATE TABLE US_POPULATION (date STRING, value BIGINT)')
      sqlContext.sql('INSERT INTO US_POPULATION VALUES ("1960", 100)')
      dbutils.notebook.run('../main_notebook_sql', 600)  

   # ************** Test Case 1 ********************
   # Act
   def run_Records_Exist_Returns_Positive_Number(self):      
      temp_result = sqlContext.sql('SELECT TOTAL FROM POPULATION_COUNT LIMIT 1')
      Test1Fixture.total = temp_result.first()[0]

   #Assert
   def assertion_Records_Exist_Returns_Positive_Number(self):      
      assert (Test1Fixture.total > 0)

   #Clean
   def after_Records_Exist_Returns_Positive_Number(self):
       sqlContext.sql('DROP TABLE IF EXISTS POPULATION_COUNT;')

   # ************** Test Case 2 ********************
   # Act
   def run_First_Year_Returns_One_Record(self):      
      temp_result = sqlContext.sql('SELECT COUNT(*) AS TOTAL FROM FIRST_YEAR_POPULATION WHERE YEAR = "1960"')
      Test1Fixture.first_year = temp_result.first()[0]

   #Assert
   def assertion_First_Year_Returns_One_Record(self):      
      assert (Test1Fixture.first_year > 0)

   #Clean
   def after_First_Year_Returns_One_Record(self):
       sqlContext.sql('DROP TABLE IF EXISTS FIRST_YEAR_POPULATION;')
        
   # ************** Clean All ********************
   def after_all(self):
       sqlContext.sql('DROP TABLE IF EXISTS US_POPULATION;')
  


# COMMAND ----------

result = Test1Fixture().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
is_job = dbutils.notebook.entry_point.getDbutils().notebook().getContext().currentRunId().isDefined()
if is_job:
  result.exit(dbutils)
