# Azure Databricks Testing Strategy and Implementation Guide

This document provides comprehensive guidance for implementing robust testing strategies in Azure Databricks projects, including unit testing, integration testing, data quality validation, and performance testing based on proven enterprise patterns.

## Testing Framework Overview

A comprehensive Databricks testing strategy includes multiple layers of validation:

1. **Unit Tests** - Test individual functions and data transformations
2. **Integration Tests** - Test end-to-end pipeline execution
3. **Data Quality Tests** - Validate business rules and data integrity
4. **Performance Tests** - Ensure acceptable processing times and resource usage
5. **Infrastructure Tests** - Validate deployment and configuration

## Unit Testing Implementation

### Python Package Testing Structure

**Directory Structure**:
```
src/
└── {project_name}_transform/
    ├── __init__.py
    ├── bronze.py
    ├── silver.py
    ├── gold.py
    ├── utilities.py
    └── tests/
        ├── __init__.py
        ├── conftest.py
        ├── test_bronze.py
        ├── test_silver.py
        ├── test_gold.py
        ├── test_utilities.py
        └── fixtures/
            ├── sample_bronze_data.json
            ├── sample_silver_data.json
            └── expected_outputs.json
```

### Test Configuration (conftest.py)

```python
# src/{project_name}_transform/tests/conftest.py
import pytest
import os
import sys
from pyspark.sql import SparkSession
from delta import configure_spark_with_delta_pip

# Add project root to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

@pytest.fixture(scope="session")
def spark():
    """
    Create a Spark session for testing with Delta Lake support
    """
    builder = SparkSession.builder \
        .appName("Unit Testing") \
        .master("local[2]") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .config("spark.sql.warehouse.dir", "/tmp/spark-warehouse") \
        .config("spark.databricks.delta.retentionDurationCheck.enabled", "false")
    
    spark = configure_spark_with_delta_pip(builder).getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    
    yield spark
    
    spark.stop()

@pytest.fixture(scope="session")
def test_data_path():
    """
    Path to test data fixtures
    """
    return os.path.join(os.path.dirname(__file__), 'fixtures')

@pytest.fixture
def sample_bronze_data(spark, test_data_path):
    """
    Load sample bronze data for testing
    """
    return spark.read.json(os.path.join(test_data_path, 'sample_bronze_data.json'))

@pytest.fixture
def expected_silver_output(spark, test_data_path):
    """
    Load expected silver output for validation
    """
    return spark.read.json(os.path.join(test_data_path, 'expected_silver_output.json'))
```

### Unit Test Examples

**Bronze Layer Testing** (test_bronze.py):
```python
# src/{project_name}_transform/tests/test_bronze.py
import pytest
import datetime
from pyspark.sql.functions import col, count, isnull
from {project_name}_transform.bronze import ingest_raw_data, add_technical_metadata

class TestBronzeProcessing:
    
    def test_ingest_raw_data_structure(self, spark, sample_bronze_data):
        """Test that raw data ingestion preserves original structure"""
        # Arrange
        load_id = 1
        loaded_on = datetime.datetime.now()
        
        # Act
        result_df = ingest_raw_data(sample_bronze_data, load_id, loaded_on)
        
        # Assert
        assert result_df.count() > 0
        assert '_ingested_at' in result_df.columns
        assert '_load_id' in result_df.columns
        assert '_source_file' in result_df.columns
        
        # Verify no data loss
        assert result_df.count() == sample_bronze_data.count()
    
    def test_add_technical_metadata(self, spark):
        """Test technical metadata addition"""
        # Arrange
        test_df = spark.createDataFrame([
            {"id": 1, "name": "test1"},
            {"id": 2, "name": "test2"}
        ])
        load_id = 123
        source_system = "test_system"
        
        # Act
        result_df = add_technical_metadata(test_df, load_id, source_system)
        
        # Assert
        assert result_df.select('_load_id').distinct().collect()[0]['_load_id'] == load_id
        assert result_df.select('_source_system').distinct().collect()[0]['_source_system'] == source_system
        assert '_ingested_at' in result_df.columns
        
        # Verify original data preserved
        original_columns = test_df.columns
        for col_name in original_columns:
            assert col_name in result_df.columns
    
    def test_duplicate_handling(self, spark):
        """Test handling of duplicate records in bronze layer"""
        # Arrange
        duplicate_data = spark.createDataFrame([
            {"id": 1, "name": "test1", "timestamp": "2024-01-01T10:00:00"},
            {"id": 1, "name": "test1", "timestamp": "2024-01-01T10:00:00"},  # Duplicate
            {"id": 2, "name": "test2", "timestamp": "2024-01-01T11:00:00"}
        ])
        
        # Act
        result_df = ingest_raw_data(duplicate_data, 1, datetime.datetime.now())
        
        # Assert - Bronze should preserve duplicates for audit trail
        assert result_df.count() == 3  # All records preserved including duplicates
    
    def test_null_value_handling(self, spark):
        """Test handling of null values in raw data"""
        # Arrange
        null_data = spark.createDataFrame([
            {"id": 1, "name": "test1", "value": 100},
            {"id": 2, "name": None, "value": 200},
            {"id": None, "name": "test3", "value": None}
        ])
        
        # Act
        result_df = ingest_raw_data(null_data, 1, datetime.datetime.now())
        
        # Assert - Bronze should preserve null values
        assert result_df.count() == 3
        assert result_df.filter(col("name").isNull()).count() == 1
        assert result_df.filter(col("id").isNull()).count() == 1
```

**Silver Layer Testing** (test_silver.py):
```python
# src/{project_name}_transform/tests/test_silver.py
import pytest
from pyspark.sql.functions import col, count
from {project_name}_transform.silver import clean_and_validate, apply_business_rules

class TestSilverProcessing:
    
    def test_data_cleaning(self, spark):
        """Test data cleaning and standardization"""
        # Arrange
        dirty_data = spark.createDataFrame([
            {"id": "1", "name": "  JOHN DOE  ", "email": "JOHN@EXAMPLE.COM", "status": "active"},
            {"id": "2", "name": "jane smith", "email": "jane@example.com", "status": "INACTIVE"},
            {"id": "3", "name": "Bob Johnson", "email": "bob@EXAMPLE.com", "status": "Active"}
        ])
        
        # Act
        cleaned_df = clean_and_validate(dirty_data)
        
        # Assert
        cleaned_records = cleaned_df.collect()
        
        # Test name standardization (trim and proper case)
        assert cleaned_records[0]['name'] == "John Doe"
        assert cleaned_records[1]['name'] == "Jane Smith"
        
        # Test email standardization (lowercase)
        assert all(record['email'].islower() for record in cleaned_records)
        
        # Test status standardization
        assert cleaned_records[0]['status'] == "Active"
        assert cleaned_records[1]['status'] == "Inactive"
    
    def test_business_rule_validation(self, spark):
        """Test application of business rules"""
        # Arrange
        test_data = spark.createDataFrame([
            {"id": 1, "age": 25, "salary": 50000, "department": "Engineering"},
            {"id": 2, "age": -5, "salary": 75000, "department": "Sales"},  # Invalid age
            {"id": 3, "age": 30, "salary": -10000, "department": "Marketing"},  # Invalid salary
            {"id": 4, "age": 35, "salary": 80000, "department": "Engineering"}
        ])
        
        # Act
        valid_df, invalid_df = apply_business_rules(test_data)
        
        # Assert
        assert valid_df.count() == 2  # Only records 1 and 4 should be valid
        assert invalid_df.count() == 2  # Records 2 and 3 should be invalid
        
        # Verify specific business rules
        valid_records = valid_df.collect()
        assert all(record['age'] > 0 for record in valid_records)
        assert all(record['salary'] > 0 for record in valid_records)
    
    def test_data_type_conversion(self, spark):
        """Test proper data type conversion"""
        # Arrange
        string_data = spark.createDataFrame([
            {"id": "1", "amount": "100.50", "date": "2024-01-01", "is_active": "true"},
            {"id": "2", "amount": "200.75", "date": "2024-01-02", "is_active": "false"}
        ])
        
        # Act
        converted_df = clean_and_validate(string_data)
        
        # Assert
        schema = converted_df.schema
        assert schema['id'].dataType.simpleString() == 'int'
        assert schema['amount'].dataType.simpleString() == 'decimal(10,2)'
        assert schema['date'].dataType.simpleString() == 'date'
        assert schema['is_active'].dataType.simpleString() == 'boolean'
    
    def test_deduplication(self, spark):
        """Test record deduplication logic"""
        # Arrange
        duplicate_data = spark.createDataFrame([
            {"id": 1, "name": "John", "updated_at": "2024-01-01T10:00:00"},
            {"id": 1, "name": "John Updated", "updated_at": "2024-01-01T12:00:00"},  # Latest
            {"id": 2, "name": "Jane", "updated_at": "2024-01-01T09:00:00"},
            {"id": 3, "name": "Bob", "updated_at": "2024-01-01T08:00:00"}
        ])
        
        # Act
        deduplicated_df = clean_and_validate(duplicate_data)
        
        # Assert
        assert deduplicated_df.count() == 3  # One duplicate removed
        
        # Verify latest record kept for duplicate ID
        john_record = deduplicated_df.filter(col("id") == 1).collect()[0]
        assert john_record['name'] == "John Updated"
```

**Gold Layer Testing** (test_gold.py):
```python
# src/{project_name}_transform/tests/test_gold.py
import pytest
from pyspark.sql.functions import col, sum as spark_sum
from {project_name}_transform.gold import create_customer_dimension, create_sales_fact

class TestGoldProcessing:
    
    def test_customer_dimension_creation(self, spark):
        """Test customer dimension table creation with SCD Type 2"""
        # Arrange
        customer_data = spark.createDataFrame([
            {"customer_id": 1, "name": "John Doe", "segment": "Premium", "effective_date": "2024-01-01"},
            {"customer_id": 1, "name": "John Doe", "segment": "VIP", "effective_date": "2024-02-01"},  # Update
            {"customer_id": 2, "name": "Jane Smith", "segment": "Standard", "effective_date": "2024-01-01"}
        ])
        
        # Act
        dimension_df = create_customer_dimension(customer_data)
        
        # Assert
        assert dimension_df.count() == 3  # All versions preserved
        
        # Test SCD Type 2 logic
        current_records = dimension_df.filter(col("is_current") == True)
        assert current_records.count() == 2  # One current record per customer
        
        # Test surrogate key generation
        assert 'customer_key' in dimension_df.columns
        assert dimension_df.select('customer_key').distinct().count() == 3
    
    def test_sales_fact_aggregation(self, spark):
        """Test sales fact table creation and aggregation"""
        # Arrange
        sales_data = spark.createDataFrame([
            {"customer_id": 1, "product_id": 1, "quantity": 2, "unit_price": 10.0, "date": "2024-01-01"},
            {"customer_id": 1, "product_id": 2, "quantity": 1, "unit_price": 20.0, "date": "2024-01-01"},
            {"customer_id": 2, "product_id": 1, "quantity": 3, "unit_price": 10.0, "date": "2024-01-02"}
        ])
        
        # Act
        fact_df = create_sales_fact(sales_data)
        
        # Assert
        assert fact_df.count() == 3
        
        # Test calculated measures
        assert 'total_amount' in fact_df.columns
        
        # Verify calculations
        customer_1_total = fact_df.filter(col("customer_id") == 1).agg(spark_sum("total_amount")).collect()[0][0]
        assert customer_1_total == 40.0  # (2*10) + (1*20)
    
    def test_business_metrics_calculation(self, spark):
        """Test business metrics and KPI calculation"""
        # Arrange
        transaction_data = spark.createDataFrame([
            {"customer_id": 1, "amount": 100.0, "transaction_date": "2024-01-01"},
            {"customer_id": 1, "amount": 150.0, "transaction_date": "2024-01-15"},
            {"customer_id": 2, "amount": 200.0, "transaction_date": "2024-01-10"}
        ])
        
        # Act
        metrics_df = create_customer_metrics(transaction_data)
        
        # Assert
        customer_1_metrics = metrics_df.filter(col("customer_id") == 1).collect()[0]
        
        assert customer_1_metrics['total_amount'] == 250.0
        assert customer_1_metrics['transaction_count'] == 2
        assert customer_1_metrics['avg_transaction_amount'] == 125.0
```

## Integration Testing Implementation

### End-to-End Pipeline Testing

**Integration Test Structure**:
```
tests/
└── integrationtests/
    ├── __init__.py
    ├── conftest.py
    ├── test_pipeline_execution.py
    ├── test_data_quality.py
    ├── test_unity_catalog_integration.py
    └── fixtures/
        ├── test_datasets/
        └── expected_outputs/
```

**Pipeline Integration Test** (test_pipeline_execution.py):
```python
# tests/integrationtests/test_pipeline_execution.py
import pytest
import os
from databricks_cli.sdk.api_client import ApiClient
from databricks_cli.jobs.api import JobsApi
from databricks_cli.runs.api import RunsApi
import time

class TestPipelineExecution:
    
    @pytest.fixture(scope="class")
    def databricks_client(self):
        """Create Databricks API client for testing"""
        host = os.environ.get('DATABRICKS_HOST')
        token = os.environ.get('DATABRICKS_TOKEN')
        
        api_client = ApiClient(host=host, token=token)
        return api_client
    
    @pytest.fixture(scope="class")
    def jobs_api(self, databricks_client):
        return JobsApi(databricks_client)
    
    @pytest.fixture(scope="class")
    def runs_api(self, databricks_client):
        return RunsApi(databricks_client)
    
    def test_bronze_to_silver_pipeline(self, jobs_api, runs_api):
        """Test bronze to silver data processing pipeline"""
        # Arrange
        job_name = "Bronze_to_Silver_Pipeline"
        job_id = self._get_job_id_by_name(jobs_api, job_name)
        
        # Act
        run_response = jobs_api.run_now(job_id, jar_params=[],
                                       notebook_params={"test_mode": "true"})
        run_id = run_response['run_id']
        
        # Wait for completion
        run_result = self._wait_for_run_completion(runs_api, run_id, timeout_minutes=30)
        
        # Assert
        assert run_result['state']['life_cycle_state'] == 'TERMINATED'
        assert run_result['state']['result_state'] == 'SUCCESS'
        
        # Validate output data
        self._validate_silver_data_quality()
    
    def test_end_to_end_medallion_pipeline(self, jobs_api, runs_api):
        """Test complete bronze → silver → gold pipeline"""
        # Arrange
        pipeline_jobs = [
            "Bronze_Ingestion_Pipeline",
            "Silver_Processing_Pipeline", 
            "Gold_Dimensional_Pipeline"
        ]
        
        # Act & Assert
        for job_name in pipeline_jobs:
            job_id = self._get_job_id_by_name(jobs_api, job_name)
            
            run_response = jobs_api.run_now(job_id, notebook_params={"test_mode": "true"})
            run_id = run_response['run_id']
            
            run_result = self._wait_for_run_completion(runs_api, run_id, timeout_minutes=45)
            
            assert run_result['state']['result_state'] == 'SUCCESS', \
                f"Pipeline {job_name} failed: {run_result.get('state', {}).get('state_message', '')}"
        
        # Final validation
        self._validate_end_to_end_data_consistency()
    
    def _get_job_id_by_name(self, jobs_api, job_name):
        """Helper to get job ID by name"""
        jobs = jobs_api.list_jobs()
        for job in jobs.get('jobs', []):
            if job.get('settings', {}).get('name') == job_name:
                return job['job_id']
        raise ValueError(f"Job '{job_name}' not found")
    
    def _wait_for_run_completion(self, runs_api, run_id, timeout_minutes=30):
        """Helper to wait for job run completion"""
        timeout_seconds = timeout_minutes * 60
        poll_interval = 30
        
        for _ in range(0, timeout_seconds, poll_interval):
            run_info = runs_api.get_run(run_id)
            state = run_info.get('state', {})
            
            if state.get('life_cycle_state') == 'TERMINATED':
                return run_info
            elif state.get('life_cycle_state') in ['INTERNAL_ERROR', 'SKIPPED']:
                raise Exception(f"Run failed with state: {state}")
            
            time.sleep(poll_interval)
        
        raise TimeoutError(f"Run {run_id} did not complete within {timeout_minutes} minutes")
    
    def _validate_silver_data_quality(self):
        """Validate silver layer data quality"""
        from pyspark.sql import SparkSession
        
        spark = SparkSession.builder.getOrCreate()
        
        # Check record counts
        silver_df = spark.table("catalog.silver.cleaned_data")
        assert silver_df.count() > 0, "Silver table is empty"
        
        # Check for null values in required fields
        null_count = silver_df.filter(
            silver_df.id.isNull() | 
            silver_df.created_date.isNull()
        ).count()
        assert null_count == 0, f"Found {null_count} records with null required fields"
    
    def _validate_end_to_end_data_consistency(self):
        """Validate data consistency across all layers"""
        from pyspark.sql import SparkSession
        
        spark = SparkSession.builder.getOrCreate()
        
        # Compare record counts between layers
        bronze_count = spark.table("catalog.bronze.raw_data").count()
        silver_count = spark.table("catalog.silver.cleaned_data").count()
        gold_count = spark.table("catalog.gold.fact_table").count()
        
        # Allow for some data filtering but ensure reasonable proportions
        assert silver_count >= bronze_count * 0.8, "Too much data lost in silver processing"
        assert gold_count > 0, "Gold layer has no data"
```

## Data Quality Testing with Great Expectations

### Data Quality Test Configuration

```python
# tests/integrationtests/test_data_quality.py
import pytest
import great_expectations as gx
from great_expectations.dataset import SparkDFDataset
from pyspark.sql import SparkSession

class TestDataQuality:
    
    @pytest.fixture(scope="class")
    def spark(self):
        return SparkSession.builder.getOrCreate()
    
    @pytest.fixture(scope="class")
    def data_context(self):
        """Initialize Great Expectations data context"""
        context = gx.get_context()
        return context
    
    def test_bronze_data_quality(self, spark, data_context):
        """Test bronze layer data quality expectations"""
        # Arrange
        bronze_df = spark.table("catalog.bronze.raw_events")
        ge_df = SparkDFDataset(bronze_df)
        
        # Act & Assert
        # Test data completeness
        result = ge_df.expect_table_row_count_to_be_between(min_value=1000, max_value=1000000)
        assert result.success, f"Bronze table row count validation failed: {result}"
        
        # Test required columns exist
        required_columns = ["_ingested_at", "_source_system", "_batch_id"]
        for column in required_columns:
            result = ge_df.expect_column_to_exist(column)
            assert result.success, f"Required column {column} missing from bronze table"
        
        # Test data freshness
        result = ge_df.expect_column_max_to_be_between(
            column="_ingested_at",
            min_value="2024-01-01",
            max_value="2030-01-01"
        )
        assert result.success, "Bronze data freshness validation failed"
    
    def test_silver_data_quality(self, spark, data_context):
        """Test silver layer data quality expectations"""
        # Arrange
        silver_df = spark.table("catalog.silver.cleaned_events")
        ge_df = SparkDFDataset(silver_df)
        
        # Act & Assert
        # Test data completeness
        result = ge_df.expect_column_to_not_be_null("event_id")
        assert result.success, "Silver table has null event_id values"
        
        # Test data validity
        result = ge_df.expect_column_values_to_be_between(
            column="amount",
            min_value=0,
            max_value=1000000
        )
        assert result.success, "Silver table has invalid amount values"
        
        # Test categorical values
        result = ge_df.expect_column_values_to_be_in_set(
            column="status",
            value_set=["Active", "Inactive", "Pending"]
        )
        assert result.success, "Silver table has invalid status values"
        
        # Test uniqueness
        result = ge_df.expect_column_values_to_be_unique("event_id")
        assert result.success, "Silver table has duplicate event_id values"
    
    def test_gold_data_quality(self, spark, data_context):
        """Test gold layer data quality expectations"""
        # Arrange
        gold_df = spark.table("catalog.gold.customer_metrics")
        ge_df = SparkDFDataset(gold_df)
        
        # Act & Assert
        # Test aggregation accuracy
        result = ge_df.expect_column_sum_to_be_between(
            column="total_amount",
            min_value=1000,
            max_value=10000000
        )
        assert result.success, "Gold table aggregation validation failed"
        
        # Test business logic
        result = ge_df.expect_column_pair_values_A_to_be_greater_than_B(
            column_A="max_amount",
            column_B="min_amount"
        )
        assert result.success, "Gold table business logic validation failed"
    
    def test_cross_layer_consistency(self, spark):
        """Test data consistency across medallion layers"""
        # Arrange
        bronze_df = spark.table("catalog.bronze.raw_events")
        silver_df = spark.table("catalog.silver.cleaned_events")
        gold_df = spark.table("catalog.gold.daily_metrics")
        
        # Act & Assert
        # Test record count consistency (allowing for reasonable data loss)
        bronze_count = bronze_df.count()
        silver_count = silver_df.count()
        
        data_retention_rate = silver_count / bronze_count
        assert data_retention_rate >= 0.85, \
            f"Too much data lost in silver processing: {data_retention_rate:.2%}"
        
        # Test aggregation consistency
        silver_total = silver_df.agg({"amount": "sum"}).collect()[0][0]
        gold_total = gold_df.agg({"total_amount": "sum"}).collect()[0][0]
        
        assert abs(silver_total - gold_total) / silver_total < 0.01, \
            "Gold aggregations inconsistent with silver data"
```

## Performance Testing

### Performance Test Implementation

```python
# tests/integrationtests/test_performance.py
import pytest
import time
from pyspark.sql import SparkSession

class TestPerformance:
    
    @pytest.fixture(scope="class")
    def spark(self):
        return SparkSession.builder.getOrCreate()
    
    def test_bronze_ingestion_performance(self, spark):
        """Test bronze layer ingestion performance"""
        # Arrange
        start_time = time.time()
        expected_max_duration = 300  # 5 minutes
        
        # Act
        result_df = spark.table("catalog.bronze.raw_events")
        record_count = result_df.count()
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Assert
        assert duration < expected_max_duration, \
            f"Bronze ingestion took {duration:.2f}s, expected < {expected_max_duration}s"
        
        # Performance benchmark
        records_per_second = record_count / duration
        assert records_per_second > 1000, \
            f"Bronze ingestion rate {records_per_second:.2f} records/sec too slow"
    
    def test_silver_processing_performance(self, spark):
        """Test silver layer processing performance"""
        # Arrange
        start_time = time.time()
        input_df = spark.table("catalog.bronze.raw_events")
        input_count = input_df.count()
        
        # Act
        output_df = spark.table("catalog.silver.cleaned_events")
        output_count = output_df.count()
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Assert
        processing_rate = input_count / duration
        assert processing_rate > 500, \
            f"Silver processing rate {processing_rate:.2f} records/sec too slow"
    
    def test_query_performance(self, spark):
        """Test analytical query performance on gold layer"""
        # Arrange
        queries = [
            "SELECT customer_id, SUM(amount) FROM catalog.gold.fact_sales GROUP BY customer_id",
            "SELECT date, COUNT(*) FROM catalog.gold.fact_sales WHERE date >= '2024-01-01' GROUP BY date",
            "SELECT * FROM catalog.gold.customer_metrics ORDER BY total_amount DESC LIMIT 100"
        ]
        
        # Act & Assert
        for query in queries:
            start_time = time.time()
            result_df = spark.sql(query)
            result_df.count()  # Trigger execution
            end_time = time.time()
            
            duration = end_time - start_time
            assert duration < 30, f"Query took {duration:.2f}s, expected < 30s: {query}"
```

## CI/CD Integration

### Test Execution in Pipelines

**Azure DevOps Pipeline Integration**:
```yaml
# azure-pipelines-ci-qa-python.yml
stages:
- stage: UnitTests
  displayName: 'Run Unit Tests'
  jobs:
  - job: PythonUnitTests
    displayName: 'Python Unit Tests'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.8'
    
    - script: |
        pip install pytest pytest-cov pyspark delta-spark great-expectations
        pip install -r requirements.txt
      displayName: 'Install dependencies'
    
    - script: |
        pytest src/*/tests/ -v --junitxml=junit/test-results.xml --cov=src --cov-report=xml
      displayName: 'Run unit tests'
    
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs:
        testResultsFiles: '**/test-*.xml'
        testRunTitle: 'Python Unit Tests'
    
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: Cobertura
        summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'

- stage: IntegrationTests
  displayName: 'Run Integration Tests'
  dependsOn: UnitTests
  condition: succeeded()
  jobs:
  - job: DatabricksIntegrationTests
    displayName: 'Databricks Integration Tests'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.8'
    
    - script: |
        pip install pytest databricks-cli great-expectations
        pip install -r requirements.txt
      displayName: 'Install dependencies'
    
    - script: |
        export DATABRICKS_HOST=$(databricksWorkspaceUrl)
        export DATABRICKS_TOKEN=$(databricksToken)
        pytest tests/integrationtests/ -v --junitxml=integration-test-results.xml
      displayName: 'Run integration tests'
      env:
        DATABRICKS_HOST: $(databricksWorkspaceUrl)
        DATABRICKS_TOKEN: $(databricksToken)
    
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs:
        testResultsFiles: '**/integration-test-results.xml'
        testRunTitle: 'Integration Tests'
```

## Best Practices and Recommendations

### Test Development Guidelines

1. **Test Isolation**: Each test should be independent and not rely on other tests
2. **Data Management**: Use fixtures for test data and clean up after tests
3. **Assertion Quality**: Write clear, specific assertions with helpful error messages
4. **Performance Awareness**: Monitor test execution time and optimize slow tests
5. **Coverage Goals**: Aim for >80% code coverage with meaningful tests

### Testing Environment Setup

1. **Separate Test Workspace**: Use dedicated Databricks workspace for testing
2. **Test Data Isolation**: Use separate Unity Catalog schemas for test data
3. **Resource Management**: Use smaller clusters for testing to control costs
4. **Secret Management**: Use test-specific secrets and configurations

### Continuous Improvement

1. **Test Metrics**: Track test execution time, coverage, and flakiness
2. **Regular Review**: Review and update tests as business logic evolves
3. **Tool Updates**: Keep testing frameworks and dependencies current
4. **Team Training**: Ensure team members understand testing best practices

---

*This testing strategy provides comprehensive coverage for Databricks projects and should be adapted based on your specific requirements, data volumes, and organizational standards.*
