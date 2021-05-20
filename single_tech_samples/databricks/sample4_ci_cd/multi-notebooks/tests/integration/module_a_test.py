from runtime.nutterfixture import NutterFixture

class TestmoduleANotebook(NutterFixture):
    def run_test_module_a(self):
      print("test_name_runing")
#       dbutils.notebook.run('../../notebooks/main_notebook.py', 600)

    def assertion_test_module_a(self):
      print("assert_test_name_runing")
      assert (1 == 1)
      
result = TestmoduleANotebook().execute_tests()
print(result.to_string())
# Comment out the next line (result.exit(dbutils)) to see the test result report from within the notebook
result.exit(dbutils)