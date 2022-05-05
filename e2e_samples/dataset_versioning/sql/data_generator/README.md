# Data Generator

This Data Generator is used to populate the `dbo.source` table in the AzureSQL Database to demonstrate loading incremental data into ADLS Gen2 along with the ability to version datasets.

## Prerequisites

- [Provisioned Azure Resources by IaC (Terraform)](../../infra/README.md)
- [AzureSQL Database tables and stored procedure created](../ddl/README.md)

### Data

1. Sign-up to [Kaggle](https://www.kaggle.com/)
1. Download [LendingClub issued Loans](https://www.kaggle.com/husainsb/lendingclub-issued-loans?select=lc_loan.csv) data. It is named `lc_loan.csv`

### Software Prerequisites

If you are using [devcontainers](https://code.visualstudio.com/docs/remote/containers), you can just open in devcontainer and everything required should be installed.

If you are not using devcontainer, you require the following:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Install required Python libraries with ```pip install requirements.txt```

## Run the Python script

1. Ensure you are logged in az cli with ```az login```.
2. Take note of the provisioned KeyVault name from [provisioned Azure Resources by IaC (Terraform)](../../infra/README.md) step.
3. Run python script:
   - To **insert data into dbo.source table**, run:

    ```bash
    python main.py -v 0 -k https://{KEYVAULT_NAME}.vault.azure.net -p ./lc_loan.csv
    ```

    - To **insert *incremental* data into dbo.source table**, run:

    ```bash
    python main.py -v 1 -k https://sample.vault.azure.net -p ./lc_loan.csv
    ```

   - To **clean up the data**, run:

    ```bash
    python main.py -c -k https://{KEYVAULT_NAME}.vault.azure.net
    ```

You can get more details with `-h` flag.

## Next steps

Run Data Factory pipeline to copy data from Azure SQL Database to Azure Data Lake Gen2. [See How to use the sample for more details](../../README.md).

## Testing

```console
vscode ➜ /workspaces/modern-data-warehouse-dataops/e2e_samples/dataset_versioning/insert_sql/tests (238_insert_db ✗) $ pytest
============================================================= test session starts =============================================================
platform linux -- Python 3.8.8, pytest-6.2.3, py-1.10.0, pluggy-0.13.1
rootdir: /workspaces/modern-data-warehouse-dataops/e2e_samples/dataset_versioning/insert_sql/tests
plugins: mock-3.5.1
collected 5 items

test_main.py ...                                                                                                                        [ 60%]
test_process.py ..                                                                                                                      [100%]

============================================================== 5 passed in 0.69s ==============================================================
```
