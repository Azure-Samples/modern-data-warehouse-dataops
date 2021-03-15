# Deploying a secure Azure Databricks environment using Infrastructure as Code

## Contents

- [Deploying a secure Azure Databricks environment using Infrastructure as Code](#deploying-a-secure-azure-databricks-environment-using-infrastructure-as-code)
  - [Contents](#contents)
  - [1. Solution Overview](#1-solution-overview)
    - [1.1. Scope](#11-scope)
  - [2. Architecture](#2-architecture)
    - [2.1. Patterns](#21-patterns)
  - [3. Technologies used](#3-technologies-used)
  - [4. How to use this sample](#4-how-to-use-this-sample)
    - [4.1. Prerequisites](#41-prerequisites)
      - [4.1.1 Software Prerequisites](#411-software-prerequisites)
    - [4.2. Setup and deployment](#42-setup-and-deployment)
    - [4.3. Deployed Resources](#43-deployed-resources)
    - [4.4. Deployment validation](#44-deployment-validation)
    - [4.5. Clean-up](#45-clean-up)
  - [5. Well Architected Framework (WAF)](#5-well-architected-framework-waf)
    - [5.1. Cost Optimisation](#51-cost-optimisation)
    - [5.2. Operational Excellence](#52-operational-excellence)
    - [5.3. Performance Efficiency](#53-performance-efficiency)
    - [5.4. Reliability](#54-reliability)
    - [5.5. Security](#55-security)

## 1. Solution Overview

It is a recommended pattern for modern cloud-native applications to automate platform provisioning to achieve consistent, repeatable deployments using Infrastructure as Code (IaC). This practice is highly encouraged by organizations that run multiple environments such as Dev, Test, Performance Test, UAT, Blue and Green production environments, etc. IaC is also very effective in managing deployments when the production environments are spread across multiple regions across the globe.

Tools like Azure Resource Manager (ARM), Terraform, and the Azure Command Line Interface (CLI) enable you to declaratively script the cloud infrastructure and use software engineering practices such as testing and versioning while implementing IaC.

This sample will focus on automating the provisioning of a basic Azure Databricks environment using the Infrastructure as Code pattern

### 1.1. Scope

The following list captures the scope of this sample:

1. Provision an Azure Databricks environment using ARM templates orchestrated by a shell script.
1. The following services will be provisioned as a part of the basic Azure Databricks environment setup:
   1. Azure Databricks Workspace
   2. Azure Storage account with hierarchical namespace enabled to support ABFS
   3. Azure key vault to store secrets and access tokens

## 2. Architecture

The below diagram illustrates the deployment process flow followed in this sample:

![alt text](../Common_Assets/Images/IAC_Architecture.png "Logo Title Text 1")

### 2.1. Patterns

Following are the cloud design patterns being used by this sample:

- [External Configuration Store pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/external-configuration-store): Configuration for the deployment is persisted externally as a parameter file separate from the deployment script.
- [Federated Identity pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/federated-identity): Azure active directory is used as the federated identity store to enable seamless integration with enterprise identity providers.
- [Valet Key pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/valet-key): Azure key vault is used to manage the secrets and access toked used by the services.
- [Compensating Transaction pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction#): The script will roll back partially configured resources if the deployment is incomplete.

## 3. Technologies used

The following technologies are used to build this sample:

- [Azure Databricks](https://azure.microsoft.com/en-au/free/databricks/)
- [Azure Storage](https://azure.microsoft.com/en-au/services/storage/data-lake-storage/)
- [Azure Key Vault](https://azure.microsoft.com/en-au/services/key-vault/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)

## 4. How to use this sample

This section holds the information about usage instructions of this sample.

### 4.1. Prerequisites

The following are the prerequisites for deploying this sample :

1. [Github account](https://github.com/)
2. [Azure Account](https://azure.microsoft.com/en-au/free/search/?&ef_id=Cj0KCQiAr8bwBRD4ARIsAHa4YyLdFKh7JC0jhbxhwPeNa8tmnhXciOHcYsgPfNB7DEFFGpNLTjdTPbwaAh8bEALw_wcB:G:s&OCID=AID2000051_SEM_O2ShDlJP&MarinID=O2ShDlJP_332092752199_azure%20account_e_c__63148277493_aud-390212648371:kwd-295861291340&lnkd=Google_Azure_Brand&dclid=CKjVuKOP7uYCFVapaAoddSkKcA)
   - *Permissions needed*: ability to create and deploy to an azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.

   - Active subscription with the following [resource providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers) enabled:
     - Microsoft.Databricks
     - Microsoft.DataLakeStore
     - Microsoft.Storage
     - Microsoft.KeyVault

#### 4.1.1 Software Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed on the local machine
   - *Installation instructions* can be found [here](hhttps://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
1. For Windows users, [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

### 4.2. Setup and deployment

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#4.3.-deployed-resources) for list of deployed resources.

Below listed are the steps to deploy this sample :

1. Ensure that:
      - You are logged in to the Azure CLI. To login, run `az login`.
      - Azure CLI is targeting the Azure Subscription you want to deploy the resources to.
         - To set target Azure Subscription, run `az account set -s <AZURE_SUBSCRIPTION_ID>`
2. Fork and clone this repository. Navigate to (CD) `single_tech_samples/databricks/cluster_deployment/`.

3. Run '/deploy.sh'

### 4.3. Deployed Resources

The following resources will be deployed as a part of this sample once the script is executed:

1. Azure resource group - A logical container to host all the services required for the Azure Databricks environment.

    - Following will be the naming convention used for the resource group: rg.TBD

2. Azure Databricks workspace.

![alt text](../Common_Assets/Images/IAC_Adb.png "Logo Title Text 1")

3. Azure Storage with hierarchical namespace enabled.

![alt text](../Common_Assets/Images/IAC_Storage.png "Logo Title Text 1")

4. Azure Key vault

The following diagram illustrates all the resources in teh provisioned resource group:

**Screenshot here**

### 4.4. Deployment validation

The following steps can be performed to validate the correct deployment of this sample:

1. Users with appropriate access rights should be able to:

   1. launch the workspace from the Azure portal.
   2. Access the control plane for the storage account and key vault though Azure portal.
   3. View deployment logs in the Azure resource group
   ![alt text](../Common_Assets/Images/IAC_Deployment_Logs.png "Logo Title Text 1")

### 4.5. Clean-up

Please follow the below steps to clean up your environment :

The clean-up script can be executed to clean up the resources provisioned in this sample. Following are ste steps to execute the script:

1. Navigate to (CD) `single_tech_samples/databricks/cluster_deployment/`.

2. Run '/cleanup.sh'

## 5. Well Architected Framework (WAF)

This section highlights key pointers to align the services deployed in this sample to Microsoft Azure 'Well Architected Framework'.

### 5.1. Cost Optimisation

1. Prior to the deployment, use [Azure pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/) to determine the expected usage cost.

2. Appropriately select the [Storage redundancy](https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy) option

3. Leverage [Azure Cost Management and Billing](https://azure.microsoft.com/en-us/services/cost-management/) to track usage cost of the Azure Databricks and Storage services

4. Use [Azure Advisor](https://azure.microsoft.com/en-us/services/advisor/) to optimize deployments by leveraging the smart insights

5. Use [Azure Policies](https://azure.microsoft.com/en-us/services/azure-policy/) to define guardrails around deployment constrains to regulate cost

### 5.2. Operational Excellence

1. Ensure that the parameters passed to the deployment scripts are validated

1. Leverage parallel resource deployment where ever possible. In the scope of this sample, all the three resources can be deployed in parallel.

1. Validate compensation transactions for the deployment workflow.

### 5.3. Performance Efficiency

1. Understand billing for metered resources provisioned as a part of this sample.

1. Track deployment logs to monitor execution time to mine possibilities for optimizations.

### 5.4. Reliability

1. Define the availability requirements prior to the deployment and configure the storage and databricks service accordingly.

2. Ensure required capacity and services are available in targeted regions

3. Test the compensation transaction logic by explicitly failing a service deployment

### 5.5. Security

1. Ensure right privileges are granted to the provisioned resources.

2. Cater for regular audits to ensure ongoing Vigilance.

3. Automate the execution of the deployment script and restrict the privilages to service accounts.

4. Integrate with secure identity provider (Azure Active Directory)

