# Utils Package Refactoring

This directory contains the refactored utility modules that were previously defined inline in Jupyter notebooks using `%run` statements.

## Problem Solved

The original code had several issues:

1. **Undefined name errors**: `DataLineage` and other classes were not properly imported due to inconsistent `%run` statements
2. **Poor maintainability**: Utility classes scattered across notebooks made them hard to maintain and test
3. **No code reusability**: Utility functions duplicated across different notebooks
4. **Testing challenges**: Inline class definitions made unit testing difficult

## Solution

The refactoring:

1. **Extracted utility classes** into proper Python modules
2. **Created importable packages** with proper `__init__.py` files
3. **Replaced `%run` statements** with standard Python imports
4. **Added proper error handling** for Fabric-specific imports

## Module Structure

```  # noqa
utils/
├── __init__.py          # Package initialization and exports
├── credentials.py       # Azure authentication utilities
├── data_catalog.py      # Purview integration and data lineage
└── feature_store.py     # Feature store utilities and mocks
```

### credentials.py

- `SPCredentials`: Service Principal credentials from Spark configuration
- `get_purview_account()`: Get Purview account from configuration

### data_catalog.py

- `DataAsset`: Class to represent data assets
- `DataLineage`: Class to represent data lineage relationships
- `PurviewDataCatalog`: Main class for Purview operations
- `PurviewClient`: Low-level Purview REST API client
- `CustomTypes`: Purview custom type definitions

### feature_store.py

- `MockFeatureStore`: Mock feature store for testing/development
- `fetch_logged_data()`: MLflow run data retrieval
- `get_latest_model_version()`: Get latest model version from MLflow

## Usage

### In Notebooks

```python
# Add utils to path (if needed)
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import utilities
from utils import (
    DataAsset,
    DataLineage,
    PurviewDataCatalog,
    MockFeatureStore,
    fetch_logged_data,
    SPCredentials
)

# Use the utilities
catalog = PurviewDataCatalog()
feature_store = MockFeatureStore()
```

### Testing

Run the test script to validate the refactoring:

```bash
cd /path/to/src
python test_utils.py
```

## Benefits

1. **Fixed import errors**: No more `F821 Undefined name` errors
2. **Better maintainability**: Centralized utility code
3. **Testability**: Can write unit tests for utility functions
4. **Reusability**: Utils can be imported across multiple notebooks
5. **Type safety**: Proper type hints and IDE support
6. **Error handling**: Graceful degradation when Fabric-specific modules unavailable

## Migration Notes

- **Before**: `%run "./data_catalog_and_lineage"`
- **After**: `from utils import DataAsset, DataLineage, PurviewDataCatalog`

- **Before**: Inline class definitions mixed with business logic
- **After**: Clean separation of utilities and business logic

## Dependencies

The utils package handles missing dependencies gracefully:

- `mlflow` - Used for model tracking (optional)
- `requests` - Used for Purview API calls
- `notebookutils` - Fabric-specific (optional, with fallbacks)
- `pyspark` - For Spark integration (optional)

When dependencies are missing, the modules provide sensible defaults or mock implementations.
