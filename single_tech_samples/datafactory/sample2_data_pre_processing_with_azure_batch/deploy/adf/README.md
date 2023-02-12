## Deploy sample ADF pipeline and required linked services.

1. `cd modern-data-warehouse-dataops/single_tech_samples/datafactory/sample2_data_pre_processing_with_azure_batch/adf`

2. Login to your Azure account.

```
az login
az account set -s <YOUR AZURE SUBSCRIPTION ID>
```

3. Set the following variables in `deploy-pipeline.sh`.

```
AZ_RESOURCE_GROUP="<YOUR-RESOURCEGROUP-NAME>"
AZ_BATCH_ACCOUNT_NAME="<YOUR-BATCH-ACCOUNT-NAME>"
AZ_BATCH_ACCOUNT_URL="<YOUR-BATCH-ACCOUNT-URL>"
AZ_BATCH_ORCHESTRATOR_POOL_ID="<YOUR-ORCHESTRATION-POOL-NAME>"
AZ_DATAFACTORY_NAME="<YOUR-DATAFACTORY-NAME>"

```
Note: Refer to [deployed resources](../terraform/README.md) to get your resource names.

4. Run `./deploy-pipeline.sh`

[Back to deployment steps](../../README.md)

