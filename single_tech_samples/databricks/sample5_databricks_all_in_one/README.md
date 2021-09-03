## Deploying secure Databricks cluster with Data exfiltration Protection and Privatelink for Storage, KeyVault and EventHub using Bicep </a> <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [1. Solution Overview](#1-solution-overview)
  - [1.1. Scope](#11-scope)
  - [1.2. Why Bicep](#12-why-bicep)
  - [1.3. Architecture](#13-architecture)
  - [1.4. Technologies used](#14-technologies-used)
- [2. How to use this sample](#2-how-to-use-this-sample)
  - [2.1. Prerequisites](#21-prerequisites)
    - [2.1.1. Client PC password](#211-client-pc-password)
  - [2.2 Deploy Options](#22-deploy-options)
    - [2.2.1 Option 1](#221-option-1)
    - [2.2.2 Option 2](#222-options-2)
- [3. Support](#3-support)
- [4. References](#4-references)
- [5. Next Steps](#5-next-steps)

## 1. Solution Overview

In this sample we are extending [sample2_enterprise_azure_datarbicks_environment](https://github.com/Azure-Samples/modern-data-warehouse-dataops/tree/single-tech/databricks_all_in_one/single_tech_samples/databricks/sample2_enterprise_azure_databricks_environment) with other services to cover the ML deployment scenarious and address operational challenges using Bicep

### 1.1 Scope

The scope of this sample is to show how to create a secure databricks cluster with Data exfiltration Protection and Privatelink for services using Bicep.

- Firewall with UDR to allow only required Databricks endpoints. [Link](https://docs.microsoft.com/en-us/azure/virtual-network/manage-network-security-group)
- Storage account with Private endpoint. [Link](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints)
- Azure Key Vault with Private endpoint. [Link](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- Create Databricks backed secret scope.
- Azure Event Hub with Private endpoint. [Link](https://docs.microsoft.com/en-us/azure/event-hubs/private-link-service)
- Create cluster with cluster logging and init script for monitoring.[Link](https://docs.microsoft.com/en-us/azure/databricks/clusters/init-scripts)
- Sample Databricks notebooks into workspace.
- Secured Windows Virtual machine with RDP (Protect data from export).[Link]
- Configure Log analytics workspace and collect metrics from spark worker node
  - Configure Diagnostic logging.[Link](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/account-settings/azure-diagnostic-logs)
  - Configure sending logs to Azure Monitor using [mspnp/spark-monitoring](https://github.com/mspnp/spark-monitoring)
  - Configure overwatch for fine grained monitoring. [Link](https://databrickslabs.github.io/overwatch/)
- Create Azure ML workspace for Model registry and assist in deploying model to AKS
- Create AKS compute for AML for real time model inference/scoring

### 1.2 Why Bicep?

Bicep is free and supported by Microsoft support and is fun, easy, and productive way to build and deploy complex infrastructure on Azure. If you are currently using ARM you will love Bicep simple syntax. Bicep also support [declaring existing resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-declaration?tabs=azure-powershell#reference-existing-resources).
More resources available at this [Link](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview#benefits-of-bicep-versus-other-tools)

### 1.3 Architecture

![Architecture](https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/main/Architecture.jpg)

- Based on best practices from <a href="https://github.com/Azure/AzureDatabricksBestPractices/blob/master/toc.md">Azure Databricks Best Practices</a> and template from <a href="https://github.com/Azure-Samples/modern-data-warehouse-dataops/tree/main/single_tech_samples/databricks/sample2_enterprise_azure_databricks_environment">Anti-Data-Exfiltration Reference architecture</a>

### 1.4 Technologies used

- [Azure Databricks](https://azure.microsoft.com/en-au/free/databricks/)

- [Azure Storage](https://azure.microsoft.com/en-au/services/storage/data-lake-storage/)
- [Azure Key Vault](https://azure.microsoft.com/en-au/services/key-vault/)
- [Azure Virtual networks](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/overview)
- [Azure Route tables](https://docs.microsoft.com/en-us/azure/virtual-network/manage-route-table)
- [Azure Public IP](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses)
- [Azure Private Links](https://docs.microsoft.com/en-us/azure/private-link/private-link-overview)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)

## 2. How to use this sample

To clone and run this repo, you'll need [Git](https://git-scm.com), [Bicep](https://github.com/Azure/bicep/blob/main/docs/installing.md) and [azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your computer. Strongly recommend to use vs code to edit the file with bicep extension installed ([instructions](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)) for intellisense and other completions.
From your command line:

### 2.1 Prerequisites

- Managed Identity needs to be enabled as a resource provider inside Azure

- For the bash script, `jq` must be installed.

### 2.1.1 Client PC password

- Client PC password complexity requirements:
The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following:
  - Contains an uppercase character
  - Contains a lowercase character
  - Contains a numeric digit
  - Contains a special character
  - Control characters are not allowed

### 2.2.1 Option 1

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flordlinus%2Fdatabricks-all-in-one-bicep-template%2Fmain%2Fazuredeploy.json)

Click on the above link to deploy the template.

### 2.2.2 Option 2

If you need to customize the template you can use the following command:

```bash
# Clone this repository
$ git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git

# Go into the repository
$ cd modern-data-warehouse-dataops/single_tech_samples/databricks/sample5_databricks_all_in_one

# Update main.bicep file with variables as required. Default is for southeastasia region.
# Refer to Azure Databricks UDR section under References for region specific parameters.
$ code main.bicep

# Run the build shell script to create the resources
$ ./build.sh
```

Note: Build script assume Linux environment, If you're using Windows, [see this guide](https://docs.microsoft.com/en-us/windows/wsl/install-win10) on running Linux

### 2.4 Support

This repo code is provided as-is and if you need help/support on bicep reach out to Azure support team (Bicep is supported by Microsoft support and 100% free to use.)

### 2.5 Reference

- [Bicep Language Spec](https://github.com/Azure/bicep/blob/main/docs/spec/bicep.md)
- [Azure Databricks UDR](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/udr)

## 3 Next Steps

- Create Databricks secret scope backed by Azure Key Vault. [Link](https://docs.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes)
- Create Azure SQL with Private link. [Link](https://docs.microsoft.com/en-us/azure/sql/private-link)
- Create an integrated ADF pipeline
- Integrate into Azure DevOps
- Create Databricks performance dashboards
- Create and configure External metastore
- Configure Databricks access to specific IP only
- More sample Databricks notebooks
- Add description to all parameters
