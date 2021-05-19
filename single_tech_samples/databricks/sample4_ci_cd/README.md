# Databricks CI/CD template 

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

When build a project in databricks, we can start from some notebooks and implement the business logic in python. Before go-production, we need to create CI/CD pipelines. To reduce the effort of build CI/CD pipelines, we build this git repository as template including sample noteboks and unit testing plus Azure DevOps yaml files as CI/CD pipelines. 

**It is the scaffolding of Azure databricks project.**

To make it easy extendable, the notebooks and python code only contain super simple logic, and the unit testing is implemented by pytest and [nutter](https://github.com/microsoft/nutter) 

This template focuses on automating provisioning, CI/CD pipeline, and various approaches of databricks implementation.

### 1.1. Scope

The following list captures the scope of this template:

1. Sample code
    1. Notebook with pyspark API.
    2. Notebook with spark sql.
    3. Multi-NotBooks (main notebook plus reusable notebooks)
    4. notebooks with python module
    5. Non-Notebook, purely python
2. Unit testing
    1. pytest for python module
    2. [nutter](https://github.com/microsoft/nutter) for notebooks
3. Provision Azure Databricks environments of development, testing and production via provision pipepline.
4. CI/CD pipelien to build and run testing automatically.

Details about [how to use this sample](#3-how-to-use-this-sample) can be found in the later sections of this document.

### 1.2. Architecture

The below diagram illustrates the deployment process flow followed in this template:

  ![architecture](images/architecture.png "architecture")



### 1.3. Technologies used

The following technologies are used to build this template:

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


### 2.2. Setup and deployment

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#4.3.-deployed-resources) for a list of deployed resources.

Below listed are the steps to deploy this template :

1. Fork and clone this repository. Navigate to (CD) `single-tech/databricks-ops/single_tech_samples/databricks/sample4_ci_cd`.

1. Provisioning resources using Azure Pipelines
  
    The easiest way to create all required Azure resources (Resource Group, Azure Databrciks, and others) is to use the Infrastructure as Code (IaC) pipeline with ARM templates. The pipeline takes care of setting up all required resources based on these [Azure Resource Manager templates](single-tech/databricks-ops/single_tech_samples/databricks/sample4_ci_cd/environment_setup/iac-create-environment-pipeline-arm.yml).

1. Create the IaC Pipeline
    
    In your Azure DevOps project, create a build pipeline from your forked repository:

    ![build pipeline](images/build-connect.png "build pipeline")

    Select the Existing Azure Pipelines YAML file option and set the path to [single-tech/databricks-ops/single_tech_samples/databricks/sample4_ci_cd/environment_setup/iac-create-environment-pipeline-arm.yml](single-tech/databricks-ops/single_tech_samples/databricks/sample4_ci_cd/environment_setup/iac-create-environment-pipeline-arm.yml)

    > TODO add screenshot of the pipeline setup

   Having done that, run the pipeline:

   > TODO add screenshot of the pipeline run



### 2.3. Deployed Resources

  Check that the newly created resources appear in the [Azure Portal](https://portal.azure.com/):

  The following resources will be deployed as a part of this template once the script is executed:

  1. Azure Databricks workspace - development.

  1. Azure Databricks workspace - staging.

  1. Azure Databricks workspace - production.

> TODO add screenshot


### 2.4. Sample project Structure
```
├── devops
|      ├──template
|      |     └──jobs
|      └──scripts
├── multi-notebooks
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   ├── notebooks
│   │      ├── main_notebook.py
│   │      ├── module_a_notebook.py
│   │      └── module_b_notebook.py
│   └── tests
│          └── integration
│               ├── main_notebook_test.py
│               ├── module_a_test.py
│               └── module_b_test.py
├── notebook-dataframe
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   ├── notebooks
│   │      └──main_notebook.py
│   └── tests
│        └── integration
│             └── main_notebook_test.py
├── notebook-sparksql
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   ├── notebooks
│   │      └──main_notebook.py
│   └── tests
│        └── integration
│             └── main_notebook_test.py
├── notebook-python-lib
│   ├── devops
│   │      ├──cd-pipeline.yml
│   │      └──ci-pipeline.yml
│   ├── common
│   │    ├── __init__.py
│   │    ├── module_a.py
│   │    └── module_b.py
│   ├── notebooks
│   │      └──main_notebook.py
│   ├── setup.py
│   └── tests
│        ├── integration
│        │    └── main_notebook_test.py
│        └── unit
│             ├── module_a_test.py
│             └── module_b_test.py
├── pyspark
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
├── provision
│   └── iac-create-environment-pipeline-arm.yml
├── .gitignore
├── README.md
├── pytest.ini
└── unit-requirements.txt

```
#### 2.4.1 multiple notebooks
#### 2.4.2 notebook by pyspark API
#### 2.4.3 notebook by sparksql
#### 2.4.4 notebook plus python module
#### 2.4.5 python spark job



