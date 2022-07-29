# Config Driven Data Pipelines

The sample demonstrate how an end to end data pipeline can be deployed by changing the configuration of an existing template implemented in Azure Databricks.

## Contents <!-- omit in toc -->

- [Solution Overview](#solution-overview)
  - [Archictecture](#architecture)
  - [Folder structure](#folder-structure)
- [How to use the sample](#how-to-use-the-sample)
  - [Prerequisites](#prerequisites)

  - [Run the example](#setup-and-deployment)


  - [Known Issues, Limitations and Workarounds](#known-issues-limitations-and-workarounds)
 
- [Key Learnings](#key-learnings)
  



---------------------
## Solution Overview
The diagram below showed the overall architecture of the solution. 

<img src= "./docs/images/architecture.png" width="800px"/>

There are two data pipelines: the one handels the configuration or master data management, i.e., defines the source and target data schema, and the one handles the transformation of fact data or event data coming from the on premise system. 

The architecture framework is buit based on Azure Databricks by spark batch job and spark streaming job. 

### Archictecture (TBC)



### Folder Structure
* The ".devcontainer" and "dev" contains the the configuration files if you plan to develop using devcontainer or on your local environment. 
* The "notebooks" are the folder contains the source notebooks files for databricks to create the controller for batch jobs (for master data processing) and streaming jobs (for event data processing). 
* The "src' folder contains the template (classes) for the CDDP solution that could be used as a foundation by changing the configuration of the template to process other type of applications data. 
* The 'test' folder contains the sample use case that developed based on the common solution template. 'fruit' is the sample application. You can refer to the example and develop your own application and define your data processing logic.  
  * Under the test folder, the 'cddp_fruit_app' folders contains the customized code to define the rules for master data and event data processing, based on the common solution template. 
  * 'cddp_fruit_app_customers' contains the different customer configurations using the same fruit application. 'config.json' is the configuration file that defines the specific information related with the customer, like customer_id, blob storage name, data transoformation rules,  etc., that the databricks job controller needs to run the pipeline for the specific customer. 

## How to use the sample

**Prerequisite**

**Option1: Use DevContainer**
* Install Microsoft VSCode Remote-Containers extension
* In VSCode, open Command Pallete and type Remote-Containers: Open Folder in Container...
* Choose the folder named ***\config_driven_data_pipelines
* Wait for the devcontainer to start. It may take a couple of minustes for the first time. 
* Recommend to use the DevContainer as it wont mess up your local environment and easily to rebuid the DevContainer when something goes terribly wrong. 
  
**Option2: Install Local Pyspark Environment**
* If you prefer not using DevcContainer, but setup local Spark with this [document](https://sigdelta.com/blog/how-to-install-pyspark-locally/)
* Open a cmd terminal window and run the script below to setup the project development. 
```
pip install -r ./src/requirements.txt
```

**Run the test example locally**

The 'cddp_fruit_app_customers' under the 'tests' folder contains the sample customer data, and customer_2 will be the one used in the example, which contains a sample master data and mocked event data as well. 

#### Step1: Master data ingestions and transformation

Sample master data has been defined in "tests/cddp_fruit_app_customers/customer_2/config.json". 
```shell
python -m cddp_solution.common.master_data_ingestion_runner tests.cddp_fruit_app customer_2 tests
python -m cddp_solution.common.master_data_transformation_runner tests.cddp_fruit_app customer_2 tests
```

#### Step2: Event data transformation
Mock events are stroed in tests/cddp_fruit_app_customers/customer_2/mock_events. 
```shell
python -m cddp_solution.common.event_data_transformation_runner tests.cddp_fruit_app customer_2 tests
```
#### step3: Event curation

```shell
python -m cddp_solution.common.event_data_curation_runner tests.cddp_fruit_app customer_2 tests
```

#### step4: Data Exoprt

```shell
python -m cddp_solution.common.curation_data_export_runner tests.cddp_fruit_app customer_2 tests
```
#### step5: check the results locally
Copy the below codes into your local notebook file, e.g., query.ipynb: 

```python
# environment setup in local notebook
from pyspark.sql import SparkSession
from pyspark import SparkConf

spark = SparkSession.getActiveSession()
if not spark:
    conf = SparkConf().setAppName("data-app").setMaster("local[*]")
    spark = SparkSession.builder.config(conf=conf)\
        .config("spark.jars.packages",
                "io.delta:delta-core_2.12:1.2.0,com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.21") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")\
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")\
        .config("spark.driver.memory", "24G")\
        .config("spark.driver.maxResultSize", "24G")\
        .enableHiveSupport()\
        .getOrCreate()

spark.sql(f"select * from customer_2_rz_fruit_app.raw_fruits_1")

# to print the tables created in raw zone
schema_name = "customer_2_rz_fruit_app"

tables = spark.sql(f"show tables in {schema_name}")

tables_collection = tables.collect()
for table in tables_collection:
    table_name = table['tableName']
    print(f"{schema_name}.{table_name}")
    

# Uncomment and replace the <> with the table name printed from above and query on the table contents 
# df = park.sql(f"select * from <table name>)
df.show()


# to print the tables created in processed zone
schema_name = "customer_2_pz_fruit_app"

tables = spark.sql(f"show tables in {schema_name}")

tables_collection = tables.collect()
for table in tables_collection:
    table_name = table['tableName']
    print(f"{schema_name}.{table_name}")

# Uncomment and replace the <> with the table name printed from above and query on the table contents 
# df = park.sql(f"select * from <table name>)
df.show()

# shutdown the notebook spark session
spark.sparkContext.stop()
spark.stop()
```
The sample table is like below: 
 <img src= "./docs/images/Sample table output.png" width="2000px"/>

## Known Issues, Limitations and Workarounds

### 1. Problem when developing with *cddp_solution* local package
When import local developed module in your Python code, you'll normally pick one of below statements, both of them may introduce module-not-found errors if you run your code in wrong path, saying we run above batch job in other path than /src.
```python
from .utils.module_helper import find_class
```
```python
from cddp_solution.common.utils.module_helper import find_class
``` 

To resolve above issues, we could install the local developed modules in editable mode.
- Prepare *pyproject.toml* and *setup.cfg* files to define which Python files should be included in wheel package.
- Run below command in path with the pyproject.toml file, to install local developed modules in editable mode.
```bash
pip install -e .
```
Once it's installed properly, we could achieve below two advantages.
- We could run/test source code in any path
- Any new chanages in source code lines of the local installed modules could take effect directly with out run the pip-install command again, as long as the *setup.cfg* file itself keeps the same, otherwise we need to execute the above pip-install command again.

### 2. The Spark session running issue during local testing/debug
If you are using the Devcontainer enviornment to run the sample locally, and if you refer to the test notebook above for local DB query, you might encounter the Spark running time issue and got errors like 
```
...
Caused by: java.sql.SQLException: Failed to start database 'metastore_db' with class loader jdk.internal.loader.ClassLoaders$AppClassLoader@5ffd2b27, see the next exception for details.
...
```
Remember to close the test notebook spark session to avoid the spark session conflct with the local dev environment. 
```
spark.sparkContext.stop()
spark.stop()
```

## Key Learnings in development

### 1. [Monitoring the Azure Databricks spark jobs.](docs/Logging.md)
### 2. [Adding unit test and integration test by Pytest framework.](tests/README.md) 