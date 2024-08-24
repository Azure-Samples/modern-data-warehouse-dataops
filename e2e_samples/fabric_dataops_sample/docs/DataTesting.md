# Testing Data Projects

## Introduction

Testing is paramount for any sysem to catch the issues early and avoid costly rework. There are different testing methodlogies and types of tests to address scenarios and vultnebaribilties in the code. Here are some key concepts:

- [Testing methodlogies](https://learn.microsoft.com/training/modules/visual-studio-test-concepts/5-testing-schools-of-thought)
- [Test pyramid and types of tests](https://learn.microsoft.com/training/modules/visual-studio-test-concepts/4-different-types-of-testing)

This article primarily focuses on unit tests that can be integrated into the [Continuous Integration (CI)](https://review.learn.microsoft.com/data-engineering/playbook/capabilities/devops-for-data/?branch=main#how-to-use-cicd-for-data) process, following the concept of [shifting testing left](https://learn.microsoft.com/devops/develop/shift-left-make-testing-fast-reliable). Shifting testing left refers to the practice of starting testing earlier in the software development lifecycle, such as during the coding phase, rather than waiting until later stages. [Microsoft Fabric](https://www.microsoft.com/microsoft-fabric/getting-started) is the platform used for demonstrating the examples in this article.

Note that while we are focusing on unit tests in this article, these concepts can be extended to all levels of test pyramid.

## Unit tests for data projects

There is no single defnition of *unit* which applies to all scenarios in the context of *unit testing*. It can be broadly mentioned as a unit or an artefact or piece of code that can be indedependtly run and tested. This varies based on the techonology stack and the domain. Here are some examples of a *unit* [See [references](#for-more-information) 1,2]:

- Functional langauages - most likely a function.
- Object-oriented language lanaguagues - single method/fucntion to entire class.
- Graphical development envrionment or Graphical User Interface (GUI) based tools - An executeable component/ouput from the tool (could be a pipeline, workflow etc.).

Unit tests are at the bottom most layer of the [testing pyramid](https://learn.microsoft.com/training/modules/visual-studio-test-concepts/5-testing-schools-of-thought), the most profilic in number, and take the least amount of time to setup and run. Here are a few things to consider while developing for better testing and code coverage:

- Organize your code for testability: For example into functions/methods/classes - this results in well defined unit boundaries.
- Make the code configuration/parameter driven: Code can be pointed to testing environments without too much mocking/stubbing.
- Consider the interfaces for integration testing: Influeces the mocking/stubbing and/or creation of test environments (files/tables/schemas etc.).
- Type of unit tests: Fulfills the core testing need (data focus or code focus) and influences the maintenance requirements on the testing code/environment.

Unit testing in data projects can differ from other types of systems, such as a front-end system. The following are some key differences:

- Cleanup costs: In data projects, the cleanup costs can be higher compared to other systems. This is because data projects often involve relational data, and mistakes or issues can have a widespread impact on the integrity and consistency of the data. Fixing data issues can be time-consuming and costly.
- Data-centric issues: Since the focus is on processing and manipulating data, the majority of issues are related to data quality, data transformations, data mappings, and data validations. Unit testing in data projects needs to specifically target these data-centric issues.
- Key-based operations: In data projects, key-based operations play a crucial role. If the key itself is incorrect or data is paritioned on wrong keys, it can lead to significant problems. While code checks can help identify issues related to key-based operations, incorrect joins based on the wrong key can have disastrous consequences, impacting the integrity and accuracy of the data.

Overall, unit testing in data projects requires a specific focus on data-related issues, ensuring data quality, and validating the accuracy of data transformations and mappings.

### Understanding unit test types

In a typical flow of unit testing in Continuous Integration (CI), various types of tests are performed to ensure high-quality code and achieve full testing code coverage. This flow may include:  linting/formatting tests, environment shakeout tests, code-based tests and data-based tests.

Balancing these different types of unit tests is key to achieving comprehensive test coverage while maintaining low maintenance effort. It ensures that the code is thoroughly tested for both functional and non-functional aspects, such as code quality, system dependencies, and data correctness. By incorporating all these test types into the CI pipeline, developers can deliver high-quality code that meets the project requirements and reduces the risk of introducing bugs or issues into the production environment.

The following offers a few more details on each type:

#### Linting/formatting tests

Linting refers to the process of analyzing your code to identify potential errors, bugs, or style violations. Formatting, on the other hand, focuses on the visual appearance and consistency of your code.

A few of the popular Python options are:
    Linters: PyFlakes, Pylint, and Flake8.
    Formatters: Black, autopep8, and yapf.

Code examples:

- Python script

    ```python
    # Install required modules
    pip install flake8 black  
    
    # To lint the code
    flake8 your_file.py  
    
    # To automatically reformat the code
    black your_file.py  
    
    # To perform the check and report issues
    black --check your_file.py # will result in non-zero exit code if there are any issues
    black --diff your_file.py # List the issues
    ```

- Python notebook options:

  - [Format code in Microsoft Fabric notebooks](https://learn.microsoft.com/fabric/data-engineering/author-notebook-format-code) using `jupyter-black`.
  
  - [Lint Jupyter notebook](https://github.com/psf/black) using `black[jupyter]`.
  
  - [QA for Jupyter notebooks](https://github.com/nbQA-dev/nbQA) using `nbQA`.
  
  - Save the notebook as a python file and run checks on the script (as shown in the above example).

#### Environment shakeout tests

An *environment shakeout* is a quick, low-load test conducted to validate the connections, availability of environment/sources, and the status of the system and its components.

In data projects, it is common to read data from multiple sources. Imagine a scenario where data from one source is unavailable, causing the process to fail in the middle. The cleanup steps would involve carefully removing corrupted or partial datasets, unless the system is idempotent. Traditionally, these tests are performed as part of shakeout/smoke testing in later phases. By shifting these lightweight tests to the left and including them as part of the Continuous Integration (CI) process, you can ensure that all necessary systems required for the process are in place preventing costly cleanups or reruns due to environment issues. Additionally, this approach helps developers verify their configuration files, ensuring they correctly point to different environments as the code moves from one environment to another (e.g., dev, test, prod).

It is possible to write these tests indendependly based on the configuration files themselves even before writing other unit tests. A few key checks performed during the environment shakeout are:

- Validating source and target connections, such as storage, key vaults, api endpoints, and databases.
- Verifying access and privileges on sources and targets, including read/write permissions.
- Checking the schema to ensure it is up-to-date.
- Assessing the status of database objects, such as identifying invalid indexes.
- Ensuring all reference/static/lookup data is available.

See [code examples](#code-examples) for sample implementation.

#### Code-based tests

Code-based tests target the functionality and logic of the code. They ensure that individual *units* of code, such as functions or classes, work as expected in isolation. These tests ensure that the code performs its required function correctly and covers all possible paths, including exceptions and error-raising scenarios/paths.

Advantages of code-based tests include:

- Lightweight and faster turnaround. Everything needed for the test is part of the unit test (no test environments to maintain).
- Isolated: Doesn't require integrations with other systems instead relying on mocking/stubbing. This makes them more reliable and easier to maintain.
- Easy generation of exceptions: These provide a controlled environment for generating and handling exceptions local to the function level.
- Mocking and Stubbing Capabilities: Can use mock or stub dependencies, such as system time or external services, by providing fixed values or predefined responses. This allows for more controlled and deterministic testing, regardless of the actual state or behavior of external systems.

One potential limitation of code-based tests is that they may not always provide significant business value. This is because the focus is primarily on the code and its functions, rather than on whether the outputs of the function align with the business needs. One way to address this limitation is by following one of the [testing methodologies](https://learn.microsoft.com/training/modules/visual-studio-test-concepts/5-testing-schools-of-thought). These methodologies provide different approaches to testing that can help ensure that the tests are aligned with the business requirements and provide meaningful value.

See [code examples](#code-examples) for sample implementation.

##### When to consider code-based tests

Consider code-based tests when:

- The code is well organized into functions, methods, and classes.
- Data mockups and stubs are easy to maintain.
- It is required to test for intermediate variables, non-deterministic outputs like sysyem/current timestamps, local log entries, and checking for errors and exceptions raised.

##### Non-ideal usecases for code-based tests

Consider other test types if:

- The unit code is significantly larger than the actual code and requires frequent maintenance.
- There is excessive stubbing and mocking, which may diminish the value of the tests.
- The unit test code is identical to the actual code.

Consider the example of a function that connects to a data source, reads the contents into a data frame, and returns that data frame. In this case, the main focus of the testing is the connection, which can be effectively tested using a shakeout approach. In this scenario, using extensive mocking for all commands and functions would result in test code that is much larger than the actual code, providing little additional value as the test case commands would be very similar to the actual code. In such cases, a shakeout and data-focused testing approach would be a better choice.

#### Data-based tests

In data projects, it is crucial to test the data processing and transformation logic. Data-based tests verify the correctness and integrity of the data, ensuring that it is processed accurately and meets the expected outcomes. These tests can include data validation, data integrity checks, and data transformation tests etc.

Advantages of data-based tests include:

- Provides the most value by checking all parts of the system, similar to mini system tests.
- Requires little to no mocking, as mocking is only done on the data side and not on code objects.
- More useful for assessing if the data meets business expectations and requirements.

Limitations of data-based tests may include:

- Initial upfront costs and ongoing maintenance of the testing environment and controlled data. This may require coordination between team members, especially when sharing the testing environment.
- Data-based tests may be slower compared to code-based tests due to the need to manipulate and load data.
- Testing exception handling may require additional effort and time to mock or prepare the necessary data.
- Non-deterministic values, such as system timestamps, need to be excluded from assertion statements as they will always fail.

See [code examples](#code-examples) for sample implementation.

##### When to consider data-based tests

Data-based tests are particularly suitable in the following scenarios:

- Data-based tests are well-suited for testing SaaS-based tools or graphical user interface (GUI) tools. These tools often involve complex interactions with data using inbuilt components/functions which can't be isolated for testing, and data-based tests can effectively validate the behavior and functionality of these tools and code implementation.
- Unorganized or complex code: When code cannot be organized into well-defined functions, methods, or classes, data-based tests can be used to validate the overall behavior of the system. These tests focus on the input and output data and can help ensure that the desired results are obtained, even in the absence of well-structured code.
- When [code-based testing is not providing much value](#non-ideal-usecases-for-code-based-tests): In some cases, code-based tests may not provide significant value or may not effectively capture the important aspects of the system. In such situations, data-based tests can be valuable in validating the data and business logic, ensuring that the system meets the expected data and business requirements.

##### Non-ideal usecases for data-based tests

Consider other testing types when:

- It is not practical to host a testing environment or when generating and maintaining controlled data is challenging. This is especially applicable when the maintenance of the testing environment is burdensome
- The testing requirements involve evaluating exception code paths or handling non-deterministic values, such as system timestamps.

### Identifying the unit test types for a given scenario

To ensure effective testing, a comprehensive evaluation of the specific requirements, system characteristics, testing goals, and areas requiring the highest level of validation and assurance is crucial. These factors should be considered when deciding whether to prioritize writing more test cases of one type over the others. It is important to note that in a typical data project, all the discussed test types are necessary for thorough and effective testing.

Here is a summary on how to choose the types of tests based on the scenarios:

- Linting/formatting tests: These must be implemented always.
- Environment shakeout tests: These should be implemented always.
- Code-based tests: See [choosing code-based tests](#when-to-consider-code-based-tests).
- Data-based tests: See [choosing data-based tests](#when-to-consider-data-based-tests).

*********** need to update file locations If we consider the "NEED to update the finanl path here for the file************************"

**Examples**:

The code in the notebook was formatted using `jupyter_black` providing a beteer formatted file.

The functions `test_env_source_connection`, `test_env_target_connection` and `test_env_keyvault_connection` are examples of environement shakeout tests. Note that these tests based on the [conguration file](../src/notebooks/resources/city_safety.cfg) used and doesn't depend on rest of the code (on how these are accessed or used etc.).

Consider `test_transform_data` which is the code-based unit test for data transformation (`transform_data`). This showcases the effective utilization of mocking for functions as well as data for trasnformation validation. Additionally, it demonstrates the implementation of static values for non-deterministic functions, such as system timestamps, using mocking. These techniques enable the verification of certain aspects that would be challenging to validate in a data-based test.

On the contrary, when examining `test_etl_steps`, it becomes apparent that the excessive use of mocking limits the scope of validation to function calls and log entries. As a result, there is a lack of thorough data validation in this test. In comparison, `test_city_safety_main` serves as a data-based test that uses a test environment to replicate the production setup, allowing the notebook to run using the simulated source data without additional mockups. This test not only emulates a real-world scenario but also validates the connections and, most importantly, the data itself. However, it does not validate exceptions related to Azure Data Lake Storage (ADLS), as simulating such failures solely within a test environment is challenging. Therefore, code-based tests are necessary to verify the exception handling code in such cases.

In conclusion, these code examples illustrate the complementary nature of different test types. Code-based tests, such as the one for `test_transform_data`, are valuable for achieving full code coverage and validating specific code functionalities. On the other hand, data-based tests, like `test_city_safety_main`, are crucial for simulating real-world scenarios, validating data, and testing connections. By employing both code-based and data-based tests, a well-rounded testing approach can be established, ensuring thorough validation, comprehensive code coverage, and effective data verification.

## Unit tests in Microsoft Fabric

### Writing unit testcases in Microsoft Fabric

Listed below are the common ways of code existence in Microft Fabric and the relavant testing options:

1. Using *external libraries**: Python scripts can be deployed as `.whl` or `.py` files. Here we are storing funtions and unit tests outside of the notebook.
   - Testing options:
     - Unit testing frameworks like [unittest](https://docs.python.org/3/library/unittest.html ) and [pytest](https://docs.pytest.org/).
   - Code organization:
     - Can be made part of the Fabric environment or resources. See below notes.
   - Pros:
     - Well established testing practices enforcing common coding standards for Python projects.
     - Direct support for linting, formatting, code-coverage etc.
     - Easy to use the code as a (common) module in all types of assets (other Python scripts, Spark Jobs, notebooks etc.).
     - Easy to work with [IDE tools like VsCode](https://learn.microsoft.com/visualstudio/python/unit-testing-python-in-visual-studio?view=vs-2022).
   - Cons:
     - Requires local development setup for project creation and library management.
     - Library updates/publishing process in Fabric takes longer time.
2. Using [*Microsoft Fabric notebooks*](https://learn.microsoft.com/fabric/data-engineering/how-to-use-notebook).
   - Testing options:
     - If the test cases are written inside a notebook - Using `ipytest`.
     - If the notebook is saved as a `.py` file - [Testing Pyspak application](https://spark.apache.org/docs/latest/api/python/getting_started/testing_pyspark.html) using frameworks like [unittest](https://docs.python.org/3/library/unittest.html) and [pytest](https://docs.pytest.org/).
   - Code organization:
     - Option 1: Unit tests use the same notebook as the code being tested.
       - Pros:
         - Less number of notebooks to maintain compared to sepearate notebook option.
         - No other tools required other than the notebook.
         - Environment settings/globals are readily available from the main code in the same notebook.
       - Cons:
         - Unit tests will run everytime code is run unless additional logic introduced to exclude unit tests based on some input arguments.
         - Diminished ability to use as code modules in another notebook without additional code.
         - Limited support for linting/formatting, no support for code coverage and testing can only be done using a notebook.
     - Option 2: Unit tests use a separate notebook than the code being tested.
       - Pros:
         - No other tools required other than the notebook.
         - Unit test cases can be run indendeptly from the code being tested.
       - Cons:
         - More number of notebooks to maintain compared to tests in the same notebook option.
         - Diminished ability to use as code modules in another notebook without additional code.
         - Limited support for linting/formatting, no support for code coverage and testing can only be done using a notebook.

**Notes*:

- In all options specfied above, these artefacts can be included either as *resources* (either as [environment resources](https://learn.microsoft.com/fabric/data-engineering/environment-manage-resources) or as [notebook resources](https://learn.microsoft.com/fabric/data-engineering/how-to-use-notebook#notebook-resources)) or as [*python libraries*](https://learn.microsoft.com/fabric/data-engineering/environment-manage-library) in a [Fabric environment](https://learn.microsoft.com/fabric/data-engineering/create-and-use-environment).
- Itis likely that management of *libraries* takes much longer than changes to *resources* when looking at the time for completion of Fabric environment publish step.
- As of Aug 2024, there is no API support to attach environment level *resources* and this can only be done using browser or use [workarounds](./ThingsToConsiderForDataProcesses.md#common-resources)

See [code examples](#code-examples) for sample implementation.

### Executing unit testcases using Microsoft Fabric notebooks

Assumptions/Known limitations:

- If you are running tests outside of Fabric envs, it is possible that some of the Fabric env specific commands can't be tested (e.g., `notebookutils.*`). So Fabric notebooks are used for all these examples.
- `%run` only recognizes notebooks from same workspace or from notebook *builtin resources* area (using `%run -b`). `notebookutils.notebook.run` can run notebooks from other workspaces but the functions in the called notebook won't be visible to current notebook (no module like treatment). So the notebook examples here uses `%run` to run the notebooks with library functions and make those functions visible to the calling notebook (or testing notebook).
- As of Aug 2024, `%run` doesn't support variable replacement option i.e., no parameters can be passed as arguments to the run command. See [run a notebook](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#reference-run-a-notebook) for details.

TIPs:

- Incase where resource updates are needed without actually making deployments to update environments - you can copy the files as *notebook resources*.
  - Example:  `notebookutils.fs.cp <source complete abfs path> {notebookutils.nbResPath}/builtin/<target_file_name>.py` and you can acccess it using `from builtin.<target_file_name> import *`
- You can also convert notebooks as python scripts and then run them. Make sure to run these scripts using `ipython <converted-notebook-script>.py` so that magic methods are resolved properly.
- [`%%capture`](https://ipython.readthedocs.io/stable/interactive/magics.html#cellmagic-capture) magic can be used to capture the output from unit test cases for further processing. Here is an example implemenation:
  
    ```python
    # cell n
    <unit test code functions>
    
    # cell n+1
    %%capture <output_global_name>
    %%ipytest.run()
    
    # cell n+2 
    print(<output_global_name>.show()) # to show the output
    print(<output_global_name>.stdout) # Console output - can be parsed and results stored somewhere or sent for further processing
    ```  

#### Using a seperate notebook for code and unit tests

Mentioned below are the typical steps when code and unit testcases are present different notebooks:

1. Create a new Fabric notebook for unit testcases.
1. Import libraries related notebook testing.

    ```python
    from unittest.mock import MagicMock, patch, call
    import pytest
    import ipytest
    
    # this makes the ipytest magic available and raise_on_error causes notebook failure incase of errors
    ipytest.autoconfig(raise_on_error=True)
   ```

1. use run magic method to load the functions which need to be tested. Ensure that we are only loading the definitions but not causing execution related cells to run. The way to ensure is use some code logic to skip code in some cells using an external parameter. See [nb-city-safety-common.ipynb](../src/notebooks/nb-city-safety-common.ipynb) for implementation example.

   ```python
   %run <notebook name from same workspace as current notebook> { "<param_to_control_which_cells_to_load>": "<param_value>" }   
   ```

1. Create and run your unit tests. There are a couple of ways these can be run:

   - Option 1 - Using cell magic `%%ipytest`
     In this option unit tests code follows the magic command results of tests are displayed when the cell is executed.

     ```python
     # All contents are in one code cell
     %%ipython

     <unit test function1 code>

     <unit test function2 code>
     ```

   - Option 2 - Using `ipytest.run()`
     This option allows exeuction command to be in a different cell than the unit tests code. Test results are displayed when the `ipytest.run()` cell is run.

     ```python
     # test functions are defined in one cell
     <unit test function1 code>

     <unit test function2 code>
     ```

     ```python
     # execution call is made in another cell
     ipytest.run()
     ```

#### Using one notebook for code and unit tests

The steps here are same as [above](#using-a-seperate-notebook-for-code-and-unit-tests) with the omission of `run <notebook>` as both code and the tests are in the same notebook. You just need to ensure that function definition cells are run before running unit tests on them.

#### Using a python script with unit tests code

Note that in this option, Spark env may not be availble to execution as we are using `subprocess`.

```python
import subprocess
import pytest

result = subprocess.run(['pytest', f'{notebookutils.nbResPath}/builtin/<python_script_with_testcases>.py', '-vv'], capture_output=True, text=True) 

stdout = result.stdout    
stderr = result.stderr  
exit_status = result.returncode 
print(exit_status)  
print(stdout)  
print(stderr)  
```

## Code examples

- ***TO DO***: Need example for same notebook

- For the notebook [nb-city-safety-common.ipynb](../src/notebooks/nb-city-safety-common.ipynb) the unit test cases are written using a sepearete notebook - [test_nb-city-safety-common.ipynb](../tests/test_nb-city-safety-common.ipynb).
- [nb-city-safety.ipynb](../src/notebooks/nb-city-safety.ipynb) uses library functions from [nb-city-safety-common.ipynb](../src/notebooks/nb-city-safety-common.ipynb) which are sourced using `%run`. 
- External parameters (`execution_mode`, `common_execution_mode` etc.) and code was used to control executions/skip execution of certain cells as needed.
- For the notebook [nb-city-safety.ipynb](../src/notebooks/nb-city-safety.ipynb) the data-based unit test cases are written are in a seperate notebook - [test_nb-city-safety.ipynb](../tests/test_nb-city-safety.ipynb).

## For more information

1. [Test pyramid - MartinFowler.com](https://martinfowler.com/articles/practical-test-pyramid.html)
1. [Testing concepts - MS Learn](https://learn.microsoft.com/training/modules/visual-studio-test-concepts)
1. [DevOps Shifting left - MS Learn](https://learn.microsoft.com/devops/develop/shift-left-make-testing-fast-reliable)
1. [Notebook testing - MS Learn](https://learn.microsoft.com/azure/databricks/notebooks/testing)
1. [Testbook - Python Unittesting for notebooks](https://github.com/nteract/testbook)

Revise and delete:

- https://www.losant.com/blog/automating-unit-tests-for-jupyter-python-notebooks-using-ipynb-and-nbmake
- https://stackoverflow.com/questions/40172281/unit-tests-for-functions-in-a-jupyter-notebook
- https://www.practitest.com/resource-center/article/system-testing-vs-integration-testing/#:~:text=The%20integration%20testing%20is%20performed,test%20engineers%2C%20and%20also%20developers.