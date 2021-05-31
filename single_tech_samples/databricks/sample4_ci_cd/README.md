# Azure Databricks CI/CD template

## Contents

- [1. Solution Overview](#1-solution-overview)
  - [1.1. Scope](#11-scope)
  - [1.2. Architecture](#12-architecture)
  - [1.3. Technologies used](#13-technologies-used)
- [2. How to use this template](#2-how-to-use-this-sample)
  - [2.1. Prerequisites](#21-prerequisites)
    - [2.1.1 Software Prerequisites](#211-software-prerequisites)
  - [2.2. Setup and deployment](#22-setup-and-deployment)
  - [2.3. Deployed Resources](#23-deployed-resources)
  - [2.4. Sample project Structure](#24-sample-project-structure)
    - [2.4.1 multiple notebooks](#241-multiple-notebooks)
    - [2.4.2 notebook by pyspark API](#242-notebook-by-pyspark-API)
    - [2.4.3 notebook by sparksql](#243-notebook-by-sparksql)
    - [2.4.4 notebook plus python module](#244-notebook-plus-python-module)
    - [2.4.5 python spark jo](#245-python-spark-job)

## 1. Solution Overview

When build a project in databricks, we can start from some notebooks and implement the business logic in Python and SparkSQL. Before go-production, we need to create CI/CD pipelines. To reduce the effort of build CI/CD pipelines, we build this git repository as template including sample noteboks and unit testing plus Azure DevOps yaml files as CI/CD pipelines.

**It is the scaffolding of Azure databricks project.**

To make it easy extendable, the notebooks and python code only contain super simple logic, and the unit testing is implemented by pytest and [nutter](https://github.com/microsoft/nutter)

This template focuses on automating provisioning, CI/CD pipeline, and various approaches of spark application implementation.

### 1.1. Scope

The following list captures the scope of this template:

1. Sample code
    1. Notebook with pyspark API, Spark SQL and multiple notebooks.
    2. Non-Notebook, purely python
    3. hybrid - python module plus notebook
2. Unit testing
    1. pytest for python module & notebooks
    2. [nutter](https://github.com/microsoft/nutter) for notebooks

3. Provision Azure Databricks environments of development, testing and production via provision pipepline.
4. CI/CD pipelien to build and run testing automatically.

Details about [how to use this sample](#3-how-to-use-this-sample) can be found in the later sections of this document.

### 1.2. Architecture

The below diagram illustrates the deployment process flow followed in this template:

  ![architecture](images/architecture.png "architecture")

### 1.3. Technologies used

The following technologies are used to build this template:

- [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/)
- [Azure Databricks](https://azure.microsoft.com/en-au/free/databricks/)
- [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)
- [nutter](https://github.com/microsoft/nutter)

## 2. How to use this template

This section holds the information about usage instructions of this template.

### 2.1. Prerequisites

The following are the prerequisites for deploying this template :

1. [Github account](https://github.com/)
2. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*:  The ability to create and deploy to an Azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.

   - Active subscription with the following [resource providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers) enabled:
     - Microsoft.Databricks
3. [DevOps for Azure Databricks](https://marketplace.visualstudio.com/items?itemName=riserrad.azdo-databricks) It is the plugin of DevOps to support Azure Databricks deployments.

### 2.2. Setup and deployment

[Please check this document to the provision of databricks and other services](devops/README.md)

### 2.3. Sample project Structure

```txt

├── devops
|   ├── config
|   ├── scripts
|   ├── template
|   |    └── jobs
│   ├── README.md
│   └── iac-create-environment-pipeline-arm.yml
├── hybrid
│   ├── README.md
│   ├── devops
│   │    ├──cd-pipeline.yml
│   │    └──ci-pipeline.yml
│   ├── common
│   │    ├── __init__.py
│   │    ├── module_a.py
│   │    ├── module_b.py
│   │    └── tests
│   │          ├── module_a_test.py
│   │          └── module_b_test.py
│   ├── notebooks
│   │    ├── main_notebook.py
│   │    └── tests
│   │          └── main_notebook_test.py
│   └── setup.py
├── notebook
│   ├── README.md
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   └── notebooks
│          ├── main_notebook.py
│          ├── main_notebook_sql.py
│          ├── module_a_notebook.py
│          └── tests
│               ├── main_notebook_sql_test.py
│               ├── main_notebook_test.py
│               ├── module_a_notebook_test.py
├── python
│   ├── README.md
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   ├── common
│   │    ├── __init__.py
│   │    ├── module_a.py
│   │    └── module_b.py
│   ├── main.py
│   ├── setup.py
│   └── tests
│        ├── integration
│        │     └── main_test.py
│        └── unit
│              ├── module_a_test.py
│              └── module_b_test.py
├── pytest.ini
├── README.md
└── unit-requirements.txt

```

In this template we offer 3 different ways to build a Spark Application with Databricks notebooks or python files.
In each sample code folder, there are

- sample notebooks or python files
- unit testing code
- Azure DevOps pipeline yaml files

#### How to use the template

1. Here is a shell script to setup your project with the template

```shell
git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git 
cd modern-data-warehouse-dataops
git checkout single-tech/databricks-ops
git archive --format=tar single-tech/databricks-ops:single_tech_samples/databricks/sample4_ci_cd | tar -x -C ../
cd ..
rm -rf modern-data-warehouse-dataops

git init
git remote add origin <your repo url>
git add -A
git commit -m "first commit"
git push -u origin --all
```

1. In your Azure DevOps project
    - create a ci pipeline and select ci-pipeline.yml. it will run unit tests and publish the artifacts when changes committed.
    - create a cd pipeline and select cd-pipeline.yml. it will run integration tests when ci pipeline successfully run and the go-production deployment can be manually triggered.

1. For notebooks based spark application, you can import notebooks samples into databricks workspace from the repo of your Azure DevOps projects. Then use Databricks to edit teh notebooks. Here is an instructions how to import it.
[https://docs.microsoft.com/en-us/azure/databricks/repos](https://docs.microsoft.com/en-us/azure/databricks/repos)

1. For python files based spark application, you can clone it to your local repo from the repo of your Azure DevOps projects, and then edit in your favorite IDE.

1. After you finshing add your logic or creating new files, you can run unit tests before you commit the changes to the repo of your Azure DevOps project. the commit will trigger the ci pipeline to run unit tests and publish artifacts.

> we don't advice to run notebooks in local with unit testing mode, so notebooks only have integration testing.
---
> Why we have 3 different ways to build spark application? As it is not supported by Databricks to build python modules. You can only do it in local IDE. And local IDE have very limited intergation with notebooks. So to meet different spark application programming approaches, we created the differenct samples.

#### 2.4.1 notebook by pyspark API and SparkSQL

This folder includes a set of notebooks "main_notebook.py" which use pyspark API, plus another notebook as its integration test.

[Please check the detail of the sample code.](notebook/README.md)

#### 2.4.2 notebook by sparksql

This folder includes a sample of notebook "main_notebook.py" which use spark sql, plus anothernotebook as its integration test.

[Please check the detail of the sample code.](notebook-sparksql/README.md)

#### 2.4.3 notebook by multiple notebooks

This folder includes 3 notebooks, the module_a and module_b notebooks are reusable notebooks. There are 3 integration testing notebooks.

[Please check the detail of the sample code.](multi-notebooks/README.md)

#### 2.4.4 notebook plus python module

This folder includes 1 notebook and 2 python files, the python files will be build as a library and import by the notebook. There are 1 integration testing notebook and 2 pytest based unit tests.

[Please check the detail of the sample code.](notebook-python-lib/README.md)

#### 2.4.5 python spark job

This folder includes 3 python files, the python files will be build as a spark job and library. There are 1 integration test and 2 pytest based unit tests.

[Please check the detail of the sample code.](pyspark/README.md)
