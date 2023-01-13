# Data Share Automation

[Azure Data Share](https://azure.microsoft.com/en-us/services/data-share/) setup requires a number of steps to establish the connection between the source data and the destination. One of those steps is sending an invitation from a source data share account and accepting the invitation in a destination data share account.

Through the portal UI, invitations can only be sent to email addresses and that requires the email recipient to perform some manual steps to accept the invitation and map the incoming data to the destination. However, the Azure Data Share SDK allows invitations to be sent to *service principals* as well, which opens up the opportunity to fully automate the process, even between different subscriptions and tenants.

This code illustrates how to perform a fully automated data sharing process between two pre-existing Data Share accounts.

## Contents

- [Working with the sample](#working-with-the-sample)
  - [source.py](#sourcepy)
  - [dest.py](#destpy)
  - [Azure Function](#azure-function)
  - [Dev Container](#dev-container)
  - [Prerequisites](#prerequisites)
    - [Bash](#bash)
    - [Powershell](#powershell)
  - [Creating the service principal](#creating-the-service-principal)
  - [Role Assignments](#role-assignments)
- [Running the sample](#running-the-sample)
  - [Sharing data](#sharing-data)
    - [Source script configuration](#source-script-configuration)
    - [Source script authentication](#source-script-authentication)
    - [Running the source script](#running-the-source-script)
  - [Receiving data](#receiving-data)
    - [Destination script configuration](#destination-script-configuration)
    - [Destination script authentication](#destination-script-authentication)
    - [Running the destination script](#running-the-destination-script)
  - [Triggering the scan](#triggering-the-scan)
  - [Using the Azure Function](#using-the-azure-function)
    - [Azure Function requirements](#azure-function-requirements)
    - [F5 experience](#f5-experience)
    - [Azure function authentication](#azure-function-authentication)
- [Removing the sample assets](#removing-the-sample-assets)

## Working with the sample

This sample includes two Python scripts and an azure function:

### source.py

- Creates a share in a data share account
- Sets up a dataset from a ADLSGen2 storage account file system
- Creates a synchronization schedule for the share
- Sends out an invitation to a service principal on a specific Azure AD tenant

### dest.py

- Lists invitations sent to the user
- Creates a subscription for a share
- Creates mappings for the shared datasets that point to an ADLSGen2 storage account file system
- Enables the scheduling trigger

### Azure Function

An Azure Function with a timer trigger is included, so the acceptance of invitations can be fully automated instead of on-demand.
This code can be found on the `azure_function` folder but it's recommended that the scripts are used for initial debugging and testing.

### Dev Container

A dev container is included to allow for an easier setup of your local dev environment. It includes all the required dependencies to execute the code and is the recommended way of testing this sample. For more information, please refer to <https://code.visualstudio.com/docs/devcontainers/containers>.

### Prerequisites

- A *source* Azure Data Share account
- A *source* Azure Storage Data Lake account (Gen2)
- A *destination* Azure Data Share account
- A *destination* Azure Storage Data Lake account (Gen2)

The *source* and *destination* assets can be created in different Azure subscriptions and tenants.

The `infra` folder includes bash and powershell scripts to setup these 4 assets in a new resource group under a single subscription. The scripts also create a container in the *source* storage account and upload this Readme.md file to it so we have some data to be shared.

> Note:
>
> - Suffix parameter should not include any special characters like '-' or '_'
> - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) is required to execute these scripts.
> - Datashare commands in Azure CLI are still in preview at the time of this writing so you may be prompted to install the extension when executing this script

#### Bash

```bash
# login
az login
# make sure the right subscription is selected
az account set -s <SUBSCRIPTION_ID>
# setup infrastructure using a suffix to avoid naming conflicts
./infra/bash_setup_infra.sh <suffix>
```

#### Powershell

```powershell
# login
az login
# make sure the right subscription is selected
az account set -s <SUBSCRIPTION_ID>
# setup infrastructure using a suffix to avoid naming conflicts
./infra/ps_setup_infra.ps1 <suffix>
```

### Creating the service principal

To automate the acceptance of the invitation, a service principal must be created in the **destination** Azure AD tenant.

```bash
az ad sp create-for-rbac --name "<insert_sp_name>"
```

It will output something like this:

```json
{
  "appId": "b50dc79f-7120-46e6-8703-1ebdb0a5e66b",
  "displayName": "<service-principal-name>",
  "name": "b50dc79f-7120-46e6-8703-1ebdb0a5e66b",
  "password": "<generated-client-secret>",
  "tenant": "<your-tenant-id>"
}
```

The **appId**, **password** and **tenant** are required by the Python scripts.

Additionally, we need the **objectId** of the service principal, which can be obtained by running the following command:

```bash
az ad sp list --display-name <insert_sp_name> --query []."id" -o tsv
```

These values will be used by the scripts through environment variables:

- `source.py` will send the invitation to our service principal using the following environment variables:
  - `DESTINATION_OBJECT_ID`: objectId
  - `DESTINATION_TENANT_ID`: tenant

- `dest.py` will execute with the service principal identity so it can accept the invitation. This is accomplished by defining the following environment variables:
  - `AZURE_CLIENT_ID`: appId
  - `AZURE_CLIENT_SECRET`: password
  - `AZURE_TENANT_ID`: tenant

The scripts are prepared to read `.env` files that include these values. Detailed instructions on how to create these files can be found further down.

### Role Assignments

> Note: If you used the *infra* scripts in this repo to create the resources, the role assignements have been setup automatically.

- The **source** data share MSI must have the **Storage Blob Data Reader** role in the source storage account

    Example:
    ![add-data-share-permissions](./media/add-data-share-permissions.png)

- The **destination** data share MSI must have the **Storage Blob Data Contributor** role in the destination storage account.

## Running the sample

### Sharing data

First we need to create the share, select the data we want to share and send an invitation. Those tasks are all automated in the `python\source.py` script.

#### Source script configuration

In the `python` folder, add a `source.env` file with the following content and update the settings to match your configuration. These should point to the **source** storage and data share accounts.

```bash
# data share details
DATA_SHARE_AZURE_SUBSCRIPTION_ID=<subscription_id>
DATA_SHARE_RESOURCE_GROUP=data-share-automation
DATA_SHARE_ACCOUNT_NAME=source-data-share<suffix>
SHARE_NAME=test-share
DATASET_NAME=test-dataset

# storage account settings
STORAGE_AZURE_SUBSCRIPTION_ID=<subscription_id>
STORAGE_RESOURCE_GROUP=data-share-automation
STORAGE_ACCOUNT_NAME=sourcestorage<suffix>
FILE_SYSTEM_NAME=share-data

# invitation recipient
DESTINATION_TENANT_ID=<destination_tenant_id>
DESTINATION_OBJECT_ID=<destination_object_id>
```

These values are used in the `python/source.py` script.

#### Source script authentication

The *source* script uses the DefaultAzureCredential class for authenticating on Azure. It uses one of several authentication mechanisms:

- The EnvironmentCredential is the first method tried by the DefaultAzureCredential class. It will look for the environment variables AZURE_CLIENT_ID, AZURE_SECRET_ID and AZURE_TENANT_ID

- It they aren't set, it will try to use Managed Identities which will be available in a hosting environment such as Azure App Service.

- If not present, it will try AZ CLI login credentials, provided az login command is ran before using it.
This is a simple way of running the script under your Azure account identity (and if you created the assets yourself, you should already have all the required permissions and roles over the resources)

The identity running the script must have the following permissions:

*Source* Data Share Account:

- **Contributor**

*Source* Storage Account:

- **Contributor**
- **User Access Administrator**

The simplest process is to run the script using your AZ CLI credentials which requires no setup as the same credentials were used to create the resources.

However, if you want to run in the context of a service principal account, you first need to ensure the permissions are correctly set and then add the following values to `source.env` file.

```bash
# service principal identity if using EnvironmentCredentials
AZURE_CLIENT_ID=client_id
AZURE_CLIENT_SECRET=client_secret
AZURE_TENANT_ID=tenant_id
```

The script is prepared to read this file if it exists and will default to using service principal credentials if these values are included.

#### Running the source script

Execute the following commands:

```bash
cd python

# not required if running in the dev container
pip install -r requirements.txt

# if using az cli credentials
az login

python source.py
```

The script should be indempotent so you can run it multiple times. As a result, you should see a share created in your *source* data share account:

![data_share_created](./media/share_created.png)

A schedule should be configured on the share:

![schedule](./media/schedule.png)

A dataset should be configured and mapped to the storage account container:

![dataset](./media/dataset.png)

Finally, an invitation should exist for the service principal:

![invitation](./media/invitation.png)

### Receiving data

Now, we need to accept the sent invitation, map the incoming data to the destination storage account and setup the schedule. Those tasks are automated in the `python\dest.py` script.

#### Destination script configuration

In the `python` folder, add a `dest.env` file with the following content and update the settings to match your configuration. These should point to the *destination* storage and data share accounts.

```bash
# data share details
DATA_SHARE_AZURE_SUBSCRIPTION_ID=c79b8ea1-f966-4bf0-b880-4c426764bbfb
DATA_SHARE_RESOURCE_GROUP=data-share-automation
DATA_SHARE_ACCOUNT_NAME=dest-data-share<suffix>

# storage account settings
STORAGE_AZURE_SUBSCRIPTION_ID=c79b8ea1-f966-4bf0-b880-4c426764bbfb
STORAGE_RESOURCE_GROUP=data-share-automation
STORAGE_ACCOUNT_NAME=deststorage<suffix>

# service principal information
AZURE_CLIENT_ID=<service_principal_app_id>
AZURE_CLIENT_SECRET=<service_principal_password>
AZURE_TENANT_ID=<service_principal_tenant>
```

> Note: while in the source.env file we used the **object_id** of the service principal as the target of the invitation, here we use the **app_id** for authentication purposes.

#### Destination script authentication

To automate the acceptance of the invitation sent to the service principal, you must run the `dest.py` script under that identity. The `dest.env` file must include the AZURE_CLIENT_ID, AZURE_CLIENT_SECRET and AZURE_TENANT_ID values.

This will ensure the script runs in the context of your service principal account and is able to access the sent invitation.

The service principal must have the following permissions:

*Destination* Data Share Account:

- **Contributor**

*Destination* Storage Account:

- **Contributor**
- **User Access Administrator**

If you want to automatically assign these permissions, you can use the `bash_setup_sp_permissions.sh` or `ps_setup_sp_permissions.sh` script in the `infra` folder:

```bash
# login
az login
# make sure the right subscription is selected
az account set -s <SUBSCRIPTION_ID>
# add permissions for the service principal objectId
./infra/bash_setup_sp_permissions.sh <suffix> <objectId>
```

```powershell
# login
az login
# make sure the right subscription is selected
az account set -s <SUBSCRIPTION_ID>
# add permissions for the service principal objectId
./infra/ps_setup_sp_permissions.ps1 <object_id_of_service_principal>
```

#### Running the destination script

Execute the following commands:

```bash
cd python

# not required if running in the dev container
pip install -r requirements.txt

python dest.py
```

After the invitation is accepted, the script can't be run again. If you need to re-run it, please create a new invitation using the `source.py` python script.

After the script executes you should see a subscription setup on the Received Shares on the *destination* azure data share account:

![subscription](./media/subscription_created.png)

You can also see the incoming data being mapped to the *destination* storage account:

![mapping](./media/mapping.png)

Finally, you can see the scheduling setup for the incoming data share:

![trigger](./media/trigger.png)

### Triggering the scan

You can now wait for the scheduled time on the data share subscription or force a snapshot sync in the destination data share account:

![snapshot](./media/snapshot.png)

Soon you will see the Readme.md file in the *destination* storage account, inside the mapped container.

### Using the Azure Function

We can take the destination script and code it as an Azure Function with a timer trigger. This way, we have a reliable way to automate the process of accepting invitations.

The `azure_function` folder includes the code required. To execute the code locally, a `local.settings.json` file should be created in the `azure_function` folder with the following content:

```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "DATA_SHARE_ACCOUNT_NAME": "",
    "DATA_SHARE_RESOURCE_GROUP_NAME": "<",
    "DATA_SHARE_AZURE_SUBSCRIPTION_ID": "",
    "DESTINATION_STORAGE_ACCOUNT_NAME": "",
    "DESTINATION_STORAGE_RESOURCE_GROUP_NAME": "",
    "DESTINATION_STORAGE_SUBSCRIPTION_ID": "",
    "AZURE_CLIENT_ID": "",
    "AZURE_CLIENT_SECRET": "",
    "AZURE_TENANT_ID": ""
  }
}
```

> Note: update these settings to match the values created for `source.env` pointing at the destination storage and data share accounts.

#### Azure Function requirements

- [Azure Function Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash) must be installed
- [Azurite extension](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite) is required for local debugging - alternatively, the AzureWebJobsStorage must be configured to use a real Azure Storage account

#### F5 experience

The `.vscode/launch.json` includes the required configuration to debug the Azure Function. Make sure the *Debug Azure Function* configuration is selected on the *Run and Debug* (Ctrl+Shift+D) options.

Before you execute the function locally, make sure Azurite is started by running the `Azurite: Start` command in Visual Studio Code.

The function will go through the same steps as the `dest.py` script detailed above and will achieve the same result.

> Note: the function will quickly exit if no invitations are found. You can use the `source.py` file on the `python` folder to setup an invitation before running the function to test the behavior.

#### Azure function authentication

Note that the function is also using the service principal created before. This will allow the function to accept the invitation but also to authenticate against the Data Share service and the destination storage account to setup the share subscription.

As a reminder the service principal must have the following permissions:

*Destination* Data Share Account:

- **Contributor**

*Destination* Storage Account:

- **Contributor**
- **User Access Administrator**

However, a good option might be to use Azure Managed Identities instead once the function is deployed to Azure. In that case, you need to perform the following steps:

- Do not include `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET` and `AZURE_TENANT_ID` in the function settings. It will default to use the managed identity for authentication and authorization.
- Make sure the managed identity of the Azure Function has the correct permissions over Data Share account and storage account (as defined above for the service principal)
- Modify `source.py` so that the invitation is sent to the objectId of the managed identity instead of the service principal. As a reminder, you can get this value by running the following command:

  ```bash
  az ad sp list --display-name <managed_identity_name> --query []."id" -o tsv
  ```

- Finally, ensure the managed identity is given the right permissions over the storage account and data share resources.
- Remember that permissions can be granted by using the `bash_setup_sp_permissions.sh` or `ps_setup_sp_permissions.sh` script in the `infra` folder.

## Removing the sample assets

If you used the scripts included in the `infra` folder to setup the infrastructure, you can simply delete the created resource group `data-share-automation` to clean up all the assets and avoid additional costs.

```bash
az group delete --resource-group data-share-automation
```
