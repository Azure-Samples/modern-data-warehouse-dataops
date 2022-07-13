# Notebook Introduction

## Setup local python env (skip this step, when using dev container)

```shell
cd ..
python -m venv pyspark-env
cd pyspark-env/Scripts
activate
cd ../../src
pip install -r requirements_dev.txt
```

## Setup environment (skip this step, when using dev container)

```shell
SET JAVA_HOME=<path-to-java>
SET HADOOP_HOME=<path-to-hadoop>
SET SPARK_HOME<path-to-spark>
SET PYSPARK_PYTHON=python
SET PYTHONPATH=%SPARK_HOME%/python;%SPARK_HOME%/python/lib/py4j-0.10.9-src.zip;
```

## Start jupyter notebooks

```shell
cd dev/notebooks
jupyter lab
```

Jupyter Lab support share Jupyter Kennel, so that we can share data across notebooks.

Open web browser and navigate to http://localhost:8888/lab?token=***