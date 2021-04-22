# How to setup

## Prepare data

1. Sign-up to [Kaggle](https://www.kaggle.com/)
1. Download [LendingClub issued Loans](https://www.kaggle.com/husainsb/lendingclub-issued-loans?select=lc_loan.csv) data. It is named `lc_loan.csv`

## Install Libraries

### Devcontainer

If you are using devcontainer, you can just open in devcontainer and everything required should be installed .

### Local

If you are not using devcontainer, you need to install required lib with ```pip install requirements.txt```

## Run your script

```az login```

Now you are good to run python main.py with different flags. You can get more details with -h flag.

### Sample execution to insert

```python main.py -v 0 -k https://sample.vault.azure.net -p ./lc_loan.csv```

### Sample execution to clean up

```python main.py -c -k https://sample.vault.azure.net```

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
