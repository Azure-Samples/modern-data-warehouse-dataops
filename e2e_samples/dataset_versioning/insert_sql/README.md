# How to setup

## Install Libraries
### Devcontainer
If you are using devcontainer, you can just open in devcontainer and everything required should be installed .

### Local
If you are not using devcontainer, you need to install required lib with ```pip install requirements.txt```

## Login to azure
```az login```

Now you are good to run python main.py with different flags. You can get more details with -h flag.


# How to test
```
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
