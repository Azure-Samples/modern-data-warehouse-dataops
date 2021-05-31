# Spark Application with Python

## Sample Application

Here is a sample spark application with python and testing based on pytest and [dbx](https://github.com/databrickslabs/dbx).

- [jobs/main.py](./jobs/main.py)

    The python uses Spark DataFrame API to process data, and it imports a method declared in the [module_a.py](./jobs/common/module_a.py).

- [jobs/module_a.py](./jobs/common/module_a.py)

    This python has a method, which is used by [main.py](./jobs/main.py).

- [tests/unit/main_test.py](./tests/unit/main_test.py)
and  [tests/unit/module_a_test.py](./tests/unit/module_a_test.py)

    These are two unit tests and they can be run with pytest and [local spark cluster](https://sigdelta.com/blog/how-to-install-pyspark-locally/).

- [tests/integration/main_test.py](./tests/integration/main_test.py)

    This is an intergation, which validate the output data in dbfs.

## Installing a project from the template

```bash
git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git 
cd modern-data-warehouse-dataops
git checkout single-tech/databricks-ops
git archive --format=tar single-tech/databricks-ops:single_tech_samples/databricks/sample4_ci_cd/python | tar -x -C ../
cd ..
rm -rf modern-data-warehouse-dataops

git init
git remote add origin <your repo url>
git add -A
git commit -m "first commit"
git push -u origin --all
```

## Installing project requirements

```bash
pip install -r unit-requirements.txt
```

## Install project package in a developer mode

```bash
pip install -e .
```

## Local Testing

For local unit testing

```bash
pytest tests/unit --cov
```

For a test on an automated job cluster, deploy the job files and then launch:

```bash
dbx deploy --job=cicd-sample-project-sample-integration-test --files-only
dbx launch --job=cicd-sample-project-sample-integration-test --as-run-submit --trace
```

You need to run the bash below first to configure dbx

```bash
dbx configure
```

## Installing CICD pipeline

1. Create a pipeline with the file [devops/azure-pipelines.yml](devops/azure-pipelines.yml)
2. Create a variable group named `Databricks-environment` with 2 variables as below:
    - `DATABRICKS_HOST` datavricks url
    - `DATABRICKS_TOKEN` databricks access token

        Here is [a docuemnt how to get the token](https://docs.databricks.com/dev-tools/api/latest/authentication.html#generate-a-personal-access-token).

## Testing and releasing via CI pipeline

- To trigger the CI pipeline, simply push your code to the repository. It shall trigger the general testing pipeline
- To trigger the release pipeline,

```bash
git tag -a v<your-project-version> -m "Release tag for version <your-project-version>"
git push origin --tags
```
