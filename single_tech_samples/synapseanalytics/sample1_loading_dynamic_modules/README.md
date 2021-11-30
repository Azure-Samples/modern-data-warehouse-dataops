# Deploying a secure Azure Databricks environment using Infrastructure as Code <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [1. Solution Overview](#1-solution-overview)
  - [1.1. Scope](#11-scope)
  - [1.2. Architecture](#12-architecture)
    - [1.2.1. Patterns](#121-patterns)
  - [1.3. Technologies used](#13-technologies-used)
- [2. How to use this sample](#2-how-to-use-this-sample)
  - [2.1. Prerequisites](#21-prerequisites)
    - [2.1.1 Software Prerequisites](#211-software-prerequisites)
  - [2.2. Setup and deployment](#22-setup-and-deployment)
  - [2.3. Deployed Resources](#23-deployed-resources)
  - [2.4. Deployment validation](#24-deployment-validation)
  - [2.5. Clean-up](#25-clean-up)
- [3. Next Step](#3-next-step)

## 1. Solution Overview

It is a recommended pattern for enterprise applications to automate platform provisioning to achieve consistent, repeatable deployments using Infrastructure as Code (IaC). This practice is highly encouraged by organizations that run multiple environments such as Dev, Test, Performance Test, UAT, Blue and Green production environments, etc. IaC is also very effective in managing deployments when the production environments are spread across multiple regions across the globe.

Tools like Azure Resource Manager (ARM), Terraform, and the Azure Command Line Interface (CLI) enable you to declaratively script the cloud infrastructure and use software engineering practices such as testing and versioning while implementing IaC.

This sample will focus on automating the provisioning of a basic Azure Databricks environment using the Infrastructure as Code pattern

### 1.1. Scope

The following list captures the scope of this sample:

1. Provision an Azure Databricks environment using ARM templates orchestrated by a shell script.
1. The following services will be provisioned as a part of the basic Azure Databricks environment setup:
   1. Azure Databricks Workspace
   2. Azure Storage account with hierarchical namespace enabled to support ABFS
   3. Azure key vault to store secrets and access tokens

Details about [how to use this sample](#3-how-to-use-this-sample) can be found in the later sections of this document.

### 1.2. Architecture

The below diagram illustrates the deployment process flow followed in this sample:

![alt text](../Common_Assets/Images/IAC_Architecture.png "Logo Title Text 1")

#### 1.2.1. Patterns

Following are the cloud design patterns being used by this sample:

- [External Configuration Store pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/external-configuration-store): Configuration for the deployment is persisted externally as a parameter file separate from the deployment script.
- [Federated Identity pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/federated-identity): Azure active directory is used as the federated identity store to enable seamless integration with enterprise identity providers.
- [Valet Key pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/valet-key): Azure key vault is used to manage the secrets and access toked used by the services.
- [Compensating Transaction pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction#): The script will roll back partially configured resources if the deployment is incomplete.

### 1.3. Technologies used

The following technologies are used to build this sample:

- [Azure Databricks](https://azure.microsoft.com/en-au/free/databricks/)
- [Azure Storage](https://azure.microsoft.com/en-au/services/storage/data-lake-storage/)
- [Azure Key Vault](https://azure.microsoft.com/en-au/services/key-vault/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)

## 2. How to use this sample

This section holds the information about usage instructions of this sample.

### 2.1. Prerequisites

The following are the prerequisites for deploying this sample :

1. [Github account](https://github.com/)
2. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*:  The ability to create and deploy to an Azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.

   - Active subscription with the following [resource providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers) enabled:

     - Microsoft.Sql
     - Microsoft.Storage
    

#### 2.1.1 Software Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed on the local machine
   - *Installation instructions* can be found [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
1. For Windows users,
   1. Option 1: [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
   2. Option 2: Use the devcontainer published [here](../.devcontainer) as a host for the bash shell.
      For more information about Devcontainers, see [here](https://code.visualstudio.com/docs/remote/containers).

### 2.2. Setup and deployment

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#4.3.-deployed-resources) for a list of deployed resources.

Below listed are the steps to deploy this sample :

1. Fork and clone this repository. Navigate to (CD) `single_tech_samples/synapseanalytics/sample1_loading_dynamic_modules/`.

1. The sample depends on the following environment variables to be set before the deployment script is run:
  
    > - `DEPLOYMENT_PREFIX` - Prefix for the resource names which will be created as a part of this deployment
    > - `AZURE_SUBSCRIPTION_ID` - Subscription ID of the Azure subscription where the resources should be deployed.
    > - `AZURE_RESOURCE_GROUP_NAME` - Name of the containing resource group
    > - `AZURE_RESOURCE_GROUP_LOCATION` - Azure region where the resources will be deployed. (e.g. australiaeast, eastus, etc.)
    > - `DELETE_RESOURCE_GROUP` - Flag to indicate the cleanup step for the resource group

1. Run '/deploy.sh'
   > Note: The script will prompt you to log in to the Azure account for authorization to deploy resources.

   The script will create the Synapse analytics workspace, Azure storage, Synapse pipelines & Synapse notebook. This script will also upload the sample file to blob storage and wheel packages to the Azure synapse.

   > Note: `DEPLOYMENT_PREFIX` for this deployment was set as `lumustest`

    ![alt text](../Common_Assets/Images/IAC_Script_Deploy.png "Logo Title Text 1")

### 2.3. Deployed Resources

The following resources will be deployed as a part of this sample once the script is executed:

1.Azure Synapse Analytics workspace.

![alt text](../Common_Assets/Images/IAC_Synapse.png "Logo Title Text 1")

2.Azure Storage with sample file.

![alt text](../Common_Assets/Images/IAC_Storage.png "Logo Title Text 1")

2.Azure Synapse spark pool with wheel packages.

![alt text](../Common_Assets/Images/IAC_Packages.png "Logo Title Text 1")

### 2.4. Deployment validation & Execution

The following steps can be performed to validate the correct deployment and execution of the sample:

* Users with appropriate access rights should be able to:

   1. Launch the synapse workspace from the Azure portal.
   2. Access the control plane for the storage account through the Azure portal.
   3. View the files uploaded in the Azure storage container

* Detail steps on how to execute the sample:

    1. Launch the Azure synapse workspace & open the synapse pipelines
    2. You'll see the pipeline with activities and some default parameters values. Click on debug or trigger to run the pipeline.
    >Note:  As part of deployment, 2 modules have already been uploaded to Azure synapse.

    ![alt text](../Common_Assets/Images/pipeline_run.png "Logo Title Text 1")

    * `storageAccountName` is Azure storage account name
    - `containerName` is Azure blob storage container name
    - `basePath` is the folder inside the container name where you want to pick the files from
    - `filPath` is file name regex with which you want to pick the files. 
    - `arhivePath`: defaults to `archive` folder inside the azure blob container
    -  In the parameters, you can specify which module you want to run with the module config as required. We'll first run it with `md5` module which doens't take any module configuration.
    - `targetTable` parameter takes a JSON object with table name and path where the parquet files will be stored for the external table. 
    - `database`: Input for the spark database ; defaults to `default` value

    3. Fill in the parameters as required (or keeping the default values) and run the pipeline. Once the pipeline is successful, you'll see the data in the spark table as defined in the `targetTable` parameter
    ![alt text](../Common_Assets/Images/spark_table.png "Logo Title Text 1")
    
    4. Now let's run the same pipeline with another module, keeping everything same except the module name, module coinfiguration and target tables.
![alt text](../Common_Assets/Images/pipeline_run_asia.png "Logo Title Text 1")

    5. Run the pipeline again with the moduleName as `data_filter` & this module will filter the data based on the filter criteria provided in the moduleConfig parameter, which in our case is "Asia" on `region` column.
    6. Once pipeline finished, you'll see a new spark table named `country_list_asia` created successfully. 
![alt text](../Common_Assets/Images/spark_table_asia.png "Logo Title Text 1")

    With this you can keep the pipeline generic & using dynamic loading of modules you'll be able to perform differnet transformations as per your need.

### 2.5. Clean-up

Please follow the below steps to clean up your environment :

The clean-up script can be executed to clean up the resources provisioned in this sample. Following are the steps to execute the script:

1. Navigate to (CD) `single_tech_samples/synapseanalytics/sample1_loading_dynamic_modules/`.

2. Run '/destroy.sh'


## 3. Next Step

