# Microsoft Fabric DataOps Sample

Microsoft Fabric is an end-to-end analytics and data platform designed for enterprises that require a unified solution. It encompasses data movement, processing, ingestion, transformation, real-time event routing, and report building. Operating on a Software as a Service (SaaS) model, Fabric brings simplicity and integration to data and analytics solutions.

This simplification comes at a cost, however. The SaaS nature of Fabric makes the DataOps process more complex. Customer needs to learn new ways of deploying, testing, and handling workspace artifacts. The CI/CD process for Fabric workspaces also differs from traditional CI/CD pipelines. For example, using Fabric deployment pipelines for promoting artifacts across environments is a unique feature of Fabric, and doesn't have a direct equivalent in other CI/CD tools.

This sample aims to provide customers a reference end-to-end (E2E) implementation of DataOps on Microsoft Fabric.

## Overview

While Fabric is an end-to-end platform, it works best when integrated with other Azure services such as Application Insights, Azure Key Vault, ADLS Gen2, Microsoft Purview and so. This dependency is also because customers have existing investments in these services and want to leverage them with Fabric.

## Infrastructure Setup

The infrastructure setup for this sample is broadly divided into two parts:

### Azure Resources

Azure resources are deployed using Terraform. The sample uses the local backend for storing the Terraform state, but it can be easily modified to use remote backends. The following resources are deployed:

- Azure Data Lake Storage Gen2 (ADLS Gen2)
- Azure Key Vault
- Azure Log Analytics Workspace
- Azure Application Insights
- Microsoft Fabric Capacity

### Fabric Resources

Microsoft Fabric resources are deployed using the [Microsoft Fabric terraform provider](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) whenever possible, or using [Microsoft Fabric REST APIs](https://learn.microsoft.com/rest/api/fabric/articles/) for resources that are still not supported by the terraform provider. The following resources are deployed:

- Microsoft Fabric Workspace
- Microsoft Fabric Lakehouse
- Azure Data Lake Storage Gen2 shortcut
- Microsoft Fabric Environment
- Microsoft Fabric Notebooks
- Microsoft Fabric Data pipelines

### Prerequisites

- An Entra user that can access Microsoft Fabric (Free license is enough).
- An Azure subscription with the following:
  - The `Microsoft.Fabric` [resource provider](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider) has been registered on the Azure subscription.
  - A resource group to which your user has been granted Contributor + User Access Administrator permissions.
  - A Service Principal:
    - *If you **cannot** create a Service Principal in your Entra ID*:
      - Request that a Service Principal be created
      - Make sure you are the **Owner** of such service principal
    - *If you **can** create a Service Principal in your Entra ID*, follow the [setting up the Infrastructure](#setting-up-the-infrastructure) section for details.
  - Request that a Fabric Administrator grant to the above service principal permission to [use Fabric APIs](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-developer#service-principals-can-use-fabric-apis).
- A bash shell with the following installed:
  - [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
  - [jq](https://jqlang.github.io/jq/download/)
  - terraform
  - python version 3.9+ with `requests` package installed
- Access to an Azure DevOps organization and project.
  - Contributor permissions to an Azure Repo in such Azure DevOps environment.

### Setting up the Infrastructure

1. Clone the repository:

    ```bash
    cd "<installation_folder>"
    # Repo clone
    git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git
    ```

1. Change the directory to the `infra` folder of the sample:

    ```bash
    cd ./modern-data-warehouse-dataops/e2e_samples/fabric_dataops_sample/infra
    ```

1. Rename the [.envtemplate](./infra/.envtemplate) file to `.env` and fill in the necessary environment variables. Here is a snipped from the environment variables file:

    ```bash
    # Tenant and Subscription variables
    export base_name="The base name of the Fabric project. This name is used for naming the Azure and Fabric resources."
    export location="The location of the Azure resources. This location is used for creating the Azure resources."
    export tenant_id="The Entra ID (Azure AD Tenant Id) of your Fabric tenant"
    export subscription_id="The Azure Subscription ID that will be used to deploy Azure resources."
    export client_id="the Client ID of the Service Principal or the Managed Identity used to deploy this script"
    export client_secret="The Service Principal Client secret"
    # ... (more variables in the file)
    ```

    Leave `ALDS_GEN2_CONNECTION_ID` blank for the first run.

1. For the following step you have 2 authentication options:
  
    1. Managed Identity authentication (Recommended as it does not require dealing with secrets).
    1. Service Principal + Client Secret authentication (required that you rotate secrets).

1. Option 1: Managed Identity Authentication
    1. Create or use an existing Azure VM and assign it a Managed Identity. For detailed steps follow the [Authenticating with Managed Identity](#optional-setting-up-an-azure-vm-for-authentication-with-managed-identity) section.
    1. Connect to the VM and open a bash shell
    1. Authenticate to Azure using the VM Managed Identity
          ```bash
          az login --identity
          ```
    1. Execute following steps from this authenticated shell

1. Option 2: Service Principal and Client Secret Authentication

    1. Create and/or configure your Service Principal [following the Microsoft Fabric Terraform provider instructions for authenticating with Service Principal and Client Secret](https://registry.terraform.io/providers/microsoft/fabric/latest/docs/guides/auth_spn_secret). 
        1. Make sure your Fabric Admin has enabled the Developer Setting [Service Principals can use Fabric APIs](https://learn.microsoft.com/en-us/fabric/admin/service-admin-portal-developer#service-principals-can-use-fabric-apis) and your Service Principal is allowed to use Fabric APIs.
        1. Grant your Service Principal Contributor + User Access Administrator permissions on the Azure resource group (see pre-requisites).
        1. Create a secret and save its value in the `.env` file for the following step.
    1. Import the environment variables file and authenticate to Azure with Service Principal
        ```bash
        source .env
        az login --service-principal -u $client_id -p $client_secret --tenant $tenant_id
        ```
    1. Execute following steps from this authenticated shell

1. Review [setup-infra.sh](./infra/setup-infra.sh) script and see if you want to adjust the derived naming of variable names of Azure/Fabric resources.

1. The Azure and Fabric resources are created using Terraform. The naming of the Azure resources is derived from the `BASE_NAME` environment variable. Please review the [main.tf](./infra/terraform/main.tf) file to understand the naming convention, and adjust it as needed.

1. Run the [setup-infra.sh](./infra/setup-infra.sh) script:

    ```bash
    ./setup-infra.sh
    ```

    The script is designed to be idempotent. Running the script multiple times will not result in duplicate resources. Instead, it will either skip or update existing resources. However, it is recommended to review the script, the output logs, and the created resources to ensure everything is as expected.

    Also, note that the bash script calls a python script [setup_fabric_environment.py](./infra/scripts/setup_fabric_environment.py) to upload custom libraries to the Fabric environment.

1. Once the deployment is complete, login to Fabric Portal and create the cloud connection to ADLS Gen2 based on the [documentation](https://learn.microsoft.com/en-us/fabric/data-factory/connector-azure-data-lake-storage-gen2#set-up-your-connection-in-a-data-pipeline). Note down the connection id.

    ![fetching-connection-id](./images/cloud-connection.png)

1. Update the `ALDS_GEN2_CONNECTION_ID` variable in the `.env` file with the connection id fetched above.

1. From this step onward you will need to authenticate using your user context. Authenticate **with user context** (required for the second run) and run the setup script again:

    ```bash
    az config set core.login_experience_v2=off
    az login --tenant $tenant_id
    az config set core.login_experience_v2=on
    ./setup-infra.sh
    ```
    
    This time, the script will create the Lakehouse shortcut to your ALDS Gen2 storage account.
    All previously deployed resources will remain unchanged.
    Fabric items whose REST APIs and terrafrom provider don't support Service Principal / Managed Identity authentication (i.e. Data Pipelines and others) will be deployed with user context authentication.

## Optional: Setting up an Azure VM for Authentication with Managed Identity

We recommend:
- creating an [Ubuntu VM](https://learn.microsoft.com/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu) and [assigning a Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-to-configure-managed-identities) to it.

- enabling [Entra login to the VM](https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-linux), this way you will have to deal with less secrets as you will be able to login to the VM from Azure cloud shell.

- leaving ssh access to the VM [disabled by default](https://learn.microsoft.com/azure/defender-for-cloud/just-in-time-access-overview), and [enabling just-in-time (JIT) ssh access to the VM](https://learn.microsoft.com/azure/defender-for-cloud/just-in-time-access-usage).

On the VM make sure you have installed the following (instructions are for Ubuntu):
- Install nano or shell text editor:
  ```bash
  sudo apt install nano
  ```
- Install az cli. Below instructions are for Ubuntu, for other distributions see instructions for [installing Azure CLI on Linux](https://learn.microsoft.com/cli/azure/install-azure-cli-linux?):
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- Install git:
  ```bash
  sudo apt install git
  ```
- [Install terraform](https://developer.hashicorp.com/terraform/install)
- Install jq:
  ```bash
  sudo apt install jq -y
  ```
- Install pip:
  ```bash
  sudo apt install python3-pip -y
  ```
- Install python requests package:
  ```bash
  python -m pip install requests
  ``` 


## Understanding the CI Process

## Running the Sample

## Cleaning up

## Known Issues, Limitations, and Workarounds

## References

- [Single-tech Sample - Fabric DataOps](./../../single_tech_samples/fabric/fabric_ci_cd/README.md)
- [Single-tech Sample - Multi-git Fabric DataOps](./../../single_tech_samples/fabric/fabric_cicd_gitlab/README.md)
- [E2E Sample - MDW Parking Sensors](./../parking_sensors/README.md)
