# run the demo

### Master data transformation

```shell
python -m cddp_solution.common.master_data_ingestion_runner tests.cddp_fruit_app customer_2 tests
python -m cddp_solution.common.master_data_transformation_runner tests.cddp_fruit_app customer_2 tests
```

### Event data transformation

```shell
python -m cddp_solution.common.event_data_transformation_runner tests.cddp_fruit_app customer_2 tests

### Event curation

```shell
python -m cddp_solution.common.event_data_curation_runner tests.cddp_fruit_app customer_2 tests
```

### Data Exoprt

```shell
python -m cddp_solution.common.curation_data_export_runner tests.cddp_fruit_app customer_2 tests
```

## Development with *cddp_solution* local package
### Problem
When import local developed module in your Python code, you'll normally pick one of below statements, both of them may introduce module-not-found errors if you run your code in wrong path, saying we run above batch job in other path than /src.
```python
from .utils.module_helper import find_class
```
```python
from cddp_solution.common.utils.module_helper import find_class
``` 

### Solution
To resolve above issues, we could install the local developed modules in editable mode.
- Prepare *pyproject.toml* and *setup.cfg* files to define which Python files should be included in wheel package.
- Run below command in path with the pyproject.toml file, to install local developed modules in editable mode.
```bash
pip install -e .
```
Once it's installed properly, we could achieve below two advantages.
- We could run/test source code in any path
- Any new chanages in source code lines of the local installed modules could take effect directly with out run the pip-install command again, as long as the *setup.cfg* file itself keeps the same, otherwise we need to execute the above pip-install command again.
