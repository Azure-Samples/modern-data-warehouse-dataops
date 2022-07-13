## About unit test and integration test

### Where to put your tests?
1. Please add unit tests into relevant modules of the __/tests__ folder.
2. And add integration tests to __/tests/integration__ folder.
3. Put test utilities to __/utils__ path 
like below hierarchy.   
|__ tests   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ integration   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ integration_test.py   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ cddp_solution   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ test_config.py     
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ cddp_fruit_app   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ cddp_fruit_app_customers   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ test_master_data_transform.py  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ cddp_flower_app
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ cddp_flower_app_customers   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|__ utils  


### Which test framework to use?
Please use __pytest__ to write your tests, then we could run below to trigger the tests run in CI pipeline.   
```sh
# Only run unit tests
pytest tests/ --ignore=integration

# Only run integration tests
pytest tests/integration/

# Generate unit tests xml report
pytest tests/ --ignore=integration --junitxml=test_report.xml

# Display unit tests coverage results in terminal
pytest --cov=src/ tests/ --ignore=integration --cov-report term

# Generate unit tests coverage report
pytest --cov=src/ tests/ --ignore=integration --cov-report xml:test_coverage.xml

# Run tests with converage config, and the .coveragerc file is in root folder,
# we could set [run], [report], [xml] configs there
pytest --cov --cov-config=.coveragerc --cov-report xml --cov-report term
```