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
     - Microsoft.Databricks
     - Microsoft.DataLakeStore
     - Microsoft.Storage
     - Microsoft.KeyVault

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

1. Fork and clone this repository. Navigate to (CD) `single_tech_samples/databricks/sample1_basic_azure_databricks_environment/`.

1. The sample depends on the following environment variables to be set before the deployment script is run:
  
    > - `DEPLOYMENT_PREFIX` - Prefix for the resource names which will be created as a part of this deployment
    > - `AZURE_SUBSCRIPTION_ID` - Subscription ID of the Azure subscription where the resources should be deployed.
    > - `AZURE_RESOURCE_GROUP_NAME` - Name of the containing resource group
    > - `AZURE_RESOURCE_GROUP_LOCATION` - Azure region where the resources will be deployed. (e.g. australiaeast, eastus, etc.)
    > - `DELETE_RESOURCE_GROUP` - Flag to indicate the cleanup step for the resource group

1. Run '/deploy.sh'
   > Note: The script will prompt you to log in to the Azure account for authorization to deploy resources.

   The script will validate the ARM templates and the environment variables before deploying the resources. It will also display the status of each stage of the deployment while it executes. The following screenshot displays the log for a successful run:

   > Note: `DEPLOYMENT_PREFIX` for this deployment was set as `lumustest`

    ![alt text](../Common_Assets/Images/IAC_Script_Deploy.png "Logo Title Text 1")

### 2.3. Deployed Resources

The following resources will be deployed as a part of this sample once the script is executed:

1.Azure Databricks workspace.

![alt text](../Common_Assets/Images/IAC_Adb.png "Logo Title Text 1")

2.Azure Storage with hierarchical namespace enabled.

![alt text](../Common_Assets/Images/IAC_Storage.png "Logo Title Text 1")

2.Azure Key vault with all the secrets configured.

![alt text](../Common_Assets/Images/IAC_Keyvault.png "Logo Title Text 1")

### 2.4. Deployment validation

The following steps can be performed to validate the correct deployment of this sample:

1. Users with appropriate access rights should be able to:

   1. launch the workspace from the Azure portal.
   2. Access the control plane for the storage account and key vault through the Azure portal.
   3. View the secrets configured in the Azure Key vault
   4. View deployment logs in the Azure resource group
   ![alt text](../Common_Assets/Images/IAC_Deployment_Logs.png "Logo Title Text 1")

### 2.5. Clean-up

Please follow the below steps to clean up your environment :

The clean-up script can be executed to clean up the resources provisioned in this sample. Following are the steps to execute the script:

1. Navigate to (CD) `single_tech_samples/databricks/sample1_basic_azure_databricks_environment/`.

2. Run '/destroy.sh'

The following screenshot displays the log for a successful clean-up run:

  ![alt text](../Common_Assets/Images/IAC_Script_Teardown.png "Logo Title Text 1")

## 3. Next Step

[Deploying Enterprise-grade Azure Databricks environment using Infrastructure as Code aligned with Anti-Data-Exfiltration Reference architecture](../sample2_enterprise_azure_databricks_environment/README.md)
