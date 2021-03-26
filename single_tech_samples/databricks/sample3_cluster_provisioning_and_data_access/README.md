# Provisioning Clusters and Access Data

In this sample we are doing a few things:

- Upload some sample data into a newly created container
- Adding the logged in account as a Storage Blob Data Contributor to enable passthrough access
- Deploy a default Databricks cluster and a High-Concurrency Databricks cluster
- Accessing data using the default cluster by mounting the Data Lake using the Account Key
- Accessing data using the high-concurrency cluster by mounting the Data Lake using AD Credential Passthrough

## Prerequisites

* You need to have already deployed the Databricks workspace using sample1
* You need to have rights to assign account roles to the storage account

## Step-by-step Deployment

### Preparation

First you need to configure your environment variable file `.env`, which should look same
or similar to the one you are using in sample1. Then run:

```
source .env
```

This will give you the configuration you need to start the following process.

Then make sure you are logged in to your Azure account via:

```
az login
```

And follow the prompts to complete your login process.

### deploy.sh

You can run ./deploy.sh to start the deployment process in the below steps.

#### upload-sample-data.sh

This step will create a new container `$storageAccountContainerName` in your storage account,
and upload the sample data file `sample-data.us-population.json` into the container.

It will then add your current account as a "Storage Blob Data Contributor" to the storage
account, which will allow you to access storage account later using AD credential passthrough.
Without this step you will get an unauthorized error when trying to read the mount point.

#### deploy-default-and-hc-clusters.sh

This step will create two clusters using the Azure Databricks RESTful API and the JSON files
located in the sample directory. One of the cluster is a basic cluster, while the other one
is a high-concurrency cluster. You would need the high-concurrency cluster for AD passthrough
configuration, and you also need a Premium Databricks workspace.

#### configure-databricks-cli.sh

This step will create a file `~/.databirckscfg` with a newly fetched AD Token and the hostname
of your Databricks workspace. This will allow you to start to use the command `databricks` in the
future steps. Note that this token expires very quickly (probably around 30 minutes), so you
may want to run this step again if you are around for longer.

#### import-data-access-notebooks.sh

This step will upload the two `.ipy` files into the root level of your Databricks workspace.
Note that there's a search-replace performed in the template before it is uploaded, which will
replace the storage account name with the correct prefix.

After you run this script, you should then login to your Databricks and run the notebooks.

Note that you need to run the AD Passthrough example in the High-Concurrency cluster, otherwise
you will get an error saying you cannot mount the storage account.

## Clean-up

To clean up the resources, go back to the sample1 and run `./destroy.sh`.

## Run sample with Sample 2 (enterprise Azure Databricks environment)

If you want to run this sample with a more restrictive network settings like in the Sample 2,
you would need to add your IP address to the Storage Account firewall prior to the deployment.

You can do it in the Azure Portal by going to "Networking" -> "Firewalls and virtual networks"
and tick "Add your client IP address", or use the command `az storage account network-rule add ...`.
