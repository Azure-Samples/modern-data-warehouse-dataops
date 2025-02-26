# Running Notebooks in Databricks

`run_experiments.ipynb` and `evaluate_experiments.ipynb` can both be run in Azure Databricks.
To do so:

- Pull the `modern-data-warehouse-dataops` repo into the Databricks workspace
- Fill out the `.env` (see unstructured_data/README.md)
- Create a compute cluster (see note)
- Navigate to notebooks and run them

Note:

- There is a current bug with the Python3.12 dependencies, so the compute cluster must install Python3.11, the Databricks 15.4LTS runtime is recommended.
