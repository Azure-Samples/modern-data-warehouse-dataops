# Deploy sample ADF pipeline and required linked services

1. `cd modern-data-warehouse-dataops/single_tech_samples/datafactory/sample3_data_pre_processing_with_azure_batch/deploy/adf`

2. Login to your Azure account.

    ```shell
    az login
    az account set -s <YOUR AZURE SUBSCRIPTION ID>
    ```

3. Set the following variables in `deploy-pipeline.

    ```shell
    AZ_RESOURCE_GROUP="<YOUR-RESOURCEGROUP-NAME>"
    AZ_BATCH_ACCOUNT_NAME="<YOUR-BATCH-ACCOUNT-NAME>"
    AZ_BATCH_ACCOUNT_URL="<YOUR-BATCH-ACCOUNT-URL>"
    AZ_BATCH_ORCHESTRATOR_POOL_ID="<YOUR-ORCHESTRATION-POOL-NAME>"
    AZ_DATAFACTORY_NAME="<YOUR-DATAFACTORY-NAME>"
    ```

    Note: Refer to [deployed resources](../terraform/README.md#deployed-resources) to get your resource names.

4. Give execute permissions to script `chmod +x deploy-pipeline.sh`

5. Run `./deploy-pipeline.sh`

[Back to deployment steps](../../README.md#setup-and-deployment)
