# Provisioning Clusters and Access Data <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [1. How to use this sample](#1-how-to-use-this-sample)
  - [1.1 Prerequisites](#11-prerequisites)
    - [1.1.1 Software Prerequisites](#111-software-prerequisites)
  - [1.2. Setup and deployment](#12-setup-and-deployment)
    - [Source Environment File](#source-environment-file)
    - [Run `deploy.sh`](#run-deploysh)
      - [upload-sample-data.sh](#upload-sample-datash)
      - [deploy-default-and-hc-clusters.sh](#deploy-default-and-hc-clusterssh)
      - [configure-databricks-cli.sh](#configure-databricks-clish)
      - [import-data-access-notebooks.sh](#import-data-access-notebookssh)
  - [1.3. Cleanup](#13-cleanup)
- [2. Run sample with Sample 2 (enterprise Azure Databricks environment)](#2-run-sample-with-sample-2-enterprise-azure-databricks-environment)

## 1. How to use this sample

In this sample we are doing a few things:

- Upload some sample data into a newly created container
- Adding the logged in account as a Storage Blob Data Contributor to enable passthrough access
- Deploy a default Databricks cluster and a High-Concurrency Databricks cluster
- Accessing data using the default cluster by mounting the Data Lake using the Account Key
- Accessing data using the high-concurrency cluster by mounting the Data Lake using AD Credential Passthrough

### 1.1 Prerequisites

1. You need to have already deployed the Databricks workspace using `sample1_basic_azure_databricks_environment`
2. You need to have rights to assign account roles to the storage account

If you would like to run this sample with sample 2, please follow
[this](#2-run-sample-with-sample-2-enterprise-azure-databricks-environment)
for a few extra setup steps.

#### 1.1.1 Software Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed on the local machine
   - *Installation instructions* can be found [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
1. For Windows users,
   1. Option 1: [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
   2. Option 2: Use the dev container published [here](../.devcontainer) as a host for the bash shell.
1. [Databricks CLI](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/cli/)

### 1.2. Setup and deployment

#### Source Environment File

First you need to configure your environment variable file `.env`, which should look same
or similar to the one you are using in `sample1`. Then run:

```bash
source .env
```

This will give you the configuration you need to start the following process.

#### Run `deploy.sh`

You can run ./deploy.sh to start the deployment process in the below steps.

```bash
./deploy.sh
```

This will execute a few scripts:

##### upload-sample-data.sh

This step will create a new container `$storageAccountContainerName` in your storage account,
and upload the sample data file `sample-data.us-population.json` into the container.

It will then add your current account as a "Storage Blob Data Contributor" to the storage
account, which will allow you to access storage account later using AD credential passthrough.
Without this step you will get an unauthorized error when trying to read the mount point.

##### deploy-default-and-hc-clusters.sh

This step will create two clusters using the Azure Databricks RESTful API and the JSON files
located in the sample directory. One of the cluster is a basic cluster, while the other one
is a high-concurrency cluster. You would need the high-concurrency cluster for AD passthrough
configuration, and you also need a Premium Databricks workspace.

##### configure-databricks-cli.sh

This step will create a file `~/.databirckscfg` with a newly fetched AD Token and the hostname
of your Databricks workspace. This will allow you to start to use the command `databricks` in the
future steps. Note that this token expires very quickly (probably around 30 minutes), so you
may want to run this step again if you are around for longer.

##### import-data-access-notebooks.sh

This step will upload the following scripts into the root level of your Databricks workspace:

- `access-data-directly-via-account-key.ipy`
- `access-data-mount-via-ad-passthrough.ipy`

Note that there's a search-replace performed in the template before it is uploaded, which will
replace the storage account name with the correct prefix.

After you run this script, you should then login to your Databricks and run the notebooks.

Note that you need to run the AD Passthrough example in the High-Concurrency cluster, otherwise
you will get an error saying you cannot mount the storage account.

### 1.3. Cleanup

To clean up the resources, go back to the sample1 and run `./destroy.sh`

```bash
./destroy.sh
```

## 2. Run sample with Sample 2 (enterprise Azure Databricks environment)

If you want to run this sample with a more restrictive network settings like in the Sample 2,
you would need to add your IP address to the Storage Account firewall prior to the deployment.

Two options:

- `From Azure Portal` by going to "Networking" -> "Firewalls and virtual networks" and tick "Add your client IP address"
- `Azure CLI` -> `az storage account network-rule add ...`.
