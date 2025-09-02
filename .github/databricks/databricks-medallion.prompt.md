# Databricks Medallion Architecture Implementation Prompt

Use this prompt to help engineers implement medallion architecture patterns in Azure Databricks with Unity Catalog, following proven enterprise patterns.

---

**Prompt for GitHub Copilot:**

You are an Azure Databricks expert specializing in medallion architecture implementation with Unity Catalog. Help me implement a robust, enterprise-grade medallion architecture (Bronze → Silver → Gold) for my data lakehouse project following the proven patterns from the Azure-Samples/modern-data-warehouse-dataops repository.

## My Project Context

**Data Sources**: [Describe your data sources - APIs, databases, files, streaming, etc.]

**Business Requirements**: [Describe what business problems you're solving and key analytics use cases]

**Data Volume**: [Approximate data volumes - records per day, file sizes, growth expectations]

**Processing Frequency**: [Real-time, micro-batch, daily, weekly, etc.]

**Compliance Requirements**: [Any regulatory, privacy, or governance requirements]

## Implementation Requirements

Please help me design and implement:

### 1. Unity Catalog Structure Design

Design a comprehensive Unity Catalog hierarchy that supports:

**Catalog Organization**:
```sql
-- Environment-specific catalogs for proper isolation
CREATE CATALOG {project}_catalog_dev;
CREATE CATALOG {project}_catalog_staging; 
CREATE CATALOG {project}_catalog_prod;

-- Schema organization by medallion layer
CREATE SCHEMA {project}_catalog_{env}.bronze COMMENT 'Raw data ingestion layer';
CREATE SCHEMA {project}_catalog_{env}.silver COMMENT 'Cleansed and validated data layer';
CREATE SCHEMA {project}_catalog_{env}.gold COMMENT 'Business-ready dimensional models';
CREATE SCHEMA {project}_catalog_{env}.sandbox COMMENT 'Development and experimentation';
```

**External Locations and Storage Credentials**:
- Configure storage credentials using managed identities
- Set up external locations for each layer with appropriate access controls
- Implement proper path organization for data lake storage

**Governance Configuration**:
- Design appropriate permissions for each layer and user role
- Configure audit logging and lineage tracking
- Implement data classification and tagging strategies

### 2. Bronze Layer Implementation

**Purpose**: Ingest raw data with minimal transformation while preserving data lineage

**Key Requirements**:
- Preserve original data format and structure exactly as received
- Add technical metadata (ingestion timestamp, source system, batch ID)
- Implement robust error handling for malformed data
- Support both batch and streaming ingestion patterns
- Maintain complete audit trail of data ingestion

**Expected Implementation**:

```python
# Bronze layer processing notebook/package
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, lit, input_file_name
from delta.tables import DeltaTable
import uuid

def ingest_to_bronze(spark, source_path, target_table, source_system):
    """
    Ingest raw data to bronze layer with technical metadata
    
    Args:
        spark: SparkSession
        source_path: Path to source data
        target_table: Unity Catalog table name (catalog.schema.table)
        source_system: Name of source system for lineage
    """
    
    # Read raw data preserving original structure
    raw_df = spark.read.option("multiline", "true").json(source_path)
    
    # Add technical metadata
    bronze_df = raw_df.select(
        "*",
        current_timestamp().alias("_ingested_at"),
        lit(source_system).alias("_source_system"),
        lit(str(uuid.uuid4())).alias("_batch_id"),
        input_file_name().alias("_source_file")
    )
    
    # Write to Delta table with merge for idempotency
    bronze_df.write.format("delta").mode("append").saveAsTable(target_table)
    
    return bronze_df.count()

# Example usage in notebook
ingested_count = ingest_to_bronze(
    spark=spark,
    source_path="abfss://raw@storage.dfs.core.windows.net/data/*.json",
    target_table="myproject_catalog_dev.bronze.raw_events",
    source_system="api_events"
)

print(f"Ingested {ingested_count} records to bronze layer")
```

**Data Organization**:
- Partition by ingestion date for efficient querying
- Store in Delta format for ACID transactions and time travel
- Implement data retention policies for cost optimization
- Configure vacuum operations for storage optimization

### 3. Silver Layer Implementation

**Purpose**: Clean, validate, and standardize data with business rules applied

**Key Requirements**:
- Implement comprehensive data quality validation
- Apply business rules and data standardization
- Handle schema evolution gracefully
- Implement data deduplication strategies
- Provide clean, analysis-ready datasets

**Expected Implementation**:

```python
# Silver layer processing with data quality validation
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
from great_expectations.dataset import SparkDFDataset
import logging

def process_to_silver(spark, source_table, target_table, business_rules):
    """
    Process bronze data to silver with quality validation
    
    Args:
        spark: SparkSession
        source_table: Source bronze table
        target_table: Target silver table
        business_rules: Dictionary of validation rules
    """
    
    # Read from bronze layer
    bronze_df = spark.table(source_table)
    
    # Apply data cleaning and standardization
    cleaned_df = bronze_df.select(
        # Extract and clean core business fields
        col("data.id").cast("string").alias("event_id"),
        col("data.timestamp").cast("timestamp").alias("event_timestamp"),
        col("data.customer_id").cast("string").alias("customer_id"),
        col("data.amount").cast("decimal(10,2)").alias("amount"),
        
        # Standardize categorical values
        when(upper(col("data.status")) == "ACTIVE", "Active")
        .when(upper(col("data.status")) == "INACTIVE", "Inactive")
        .otherwise("Unknown").alias("status"),
        
        # Technical metadata
        col("_ingested_at"),
        col("_source_system"),
        col("_batch_id"),
        current_timestamp().alias("_processed_at")
    ).filter(
        # Apply business rules
        col("event_id").isNotNull() &
        col("event_timestamp").isNotNull() &
        col("amount").between(0, 1000000)  # Business rule: reasonable amount range
    )
    
    # Data quality validation with Great Expectations
    validation_results = validate_data_quality(cleaned_df, business_rules)
    
    if validation_results.get("success", False):
        # Write to silver table with upsert logic
        perform_silver_upsert(cleaned_df, target_table)
        logging.info(f"Successfully processed {cleaned_df.count()} records to silver")
    else:
        logging.error(f"Data quality validation failed: {validation_results}")
        raise Exception("Data quality validation failed")
    
    return cleaned_df

def validate_data_quality(df, rules):
    """Validate data quality using Great Expectations"""
    ge_df = SparkDFDataset(df)
    
    results = {}
    for rule_name, rule_config in rules.items():
        if rule_config["type"] == "not_null":
            result = ge_df.expect_column_to_not_be_null(rule_config["column"])
            results[rule_name] = result.success
        elif rule_config["type"] == "range":
            result = ge_df.expect_column_values_to_be_between(
                rule_config["column"], 
                rule_config["min"], 
                rule_config["max"]
            )
            results[rule_name] = result.success
    
    return {"success": all(results.values()), "details": results}

def perform_silver_upsert(source_df, target_table):
    """Perform upsert operation to silver table"""
    from delta.tables import DeltaTable
    
    # Create table if it doesn't exist
    if not spark.catalog.tableExists(target_table):
        source_df.write.format("delta").saveAsTable(target_table)
        return
    
    # Perform upsert
    target_delta = DeltaTable.forName(spark, target_table)
    
    target_delta.alias("target").merge(
        source_df.alias("source"),
        "target.event_id = source.event_id"
    ).whenMatchedUpdate(set={
        "event_timestamp": "source.event_timestamp",
        "customer_id": "source.customer_id", 
        "amount": "source.amount",
        "status": "source.status",
        "_processed_at": "source._processed_at"
    }).whenNotMatchedInsert(values={
        "event_id": "source.event_id",
        "event_timestamp": "source.event_timestamp", 
        "customer_id": "source.customer_id",
        "amount": "source.amount",
        "status": "source.status",
        "_ingested_at": "source._ingested_at",
        "_source_system": "source._source_system",
        "_batch_id": "source._batch_id",
        "_processed_at": "source._processed_at"
    }).execute()

# Example usage
business_rules = {
    "event_id_not_null": {"type": "not_null", "column": "event_id"},
    "amount_range": {"type": "range", "column": "amount", "min": 0, "max": 1000000}
}

silver_df = process_to_silver(
    spark=spark,
    source_table="myproject_catalog_dev.bronze.raw_events",
    target_table="myproject_catalog_dev.silver.cleaned_events", 
    business_rules=business_rules
)
```

**Quality Monitoring**:
- Implement data quality metrics collection
- Set up alerting for quality threshold breaches
- Generate automated data quality reports
- Track data lineage and transformation impact

### 4. Gold Layer Implementation

**Purpose**: Create business-ready, dimensional models optimized for analytics

**Key Requirements**:
- Implement star schema or dimensional modeling patterns
- Optimize for analytical query performance
- Create business-friendly views and aggregations
- Implement slowly changing dimensions (SCD) patterns
- Provide consistent business metrics and KPIs

**Expected Implementation**:

```python
# Gold layer dimensional modeling
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.window import Window

def create_dimensional_model(spark, source_tables, target_schema):
    """
    Create dimensional model in gold layer
    
    Args:
        spark: SparkSession
        source_tables: Dictionary of source silver tables
        target_schema: Target schema for gold tables
    """
    
    # Create dimension tables
    customer_dim = create_customer_dimension(
        spark, 
        source_tables["customers"], 
        f"{target_schema}.dim_customer"
    )
    
    date_dim = create_date_dimension(
        spark,
        f"{target_schema}.dim_date"
    )
    
    # Create fact table
    event_fact = create_event_fact_table(
        spark,
        source_tables["events"],
        f"{target_schema}.fact_events"
    )
    
    return {
        "dim_customer": customer_dim,
        "dim_date": date_dim,
        "fact_events": event_fact
    }

def create_customer_dimension(spark, source_table, target_table):
    """Create Type 2 SCD customer dimension"""
    
    source_df = spark.table(source_table)
    
    # Implement SCD Type 2 logic
    window_spec = Window.partitionBy("customer_id").orderBy("_processed_at")
    
    customer_dim_df = source_df.select(
        # Generate surrogate key
        concat(col("customer_id"), lit("_"), 
               date_format(col("_processed_at"), "yyyyMMdd")).alias("customer_key"),
        col("customer_id").alias("customer_business_key"),
        col("customer_name"),
        col("customer_email"),
        col("customer_segment"),
        
        # SCD Type 2 fields
        col("_processed_at").alias("effective_date"),
        lead(col("_processed_at")).over(window_spec).alias("expiry_date"),
        when(lead(col("_processed_at")).over(window_spec).isNull(), True)
        .otherwise(False).alias("is_current"),
        
        # Audit fields
        current_timestamp().alias("created_timestamp"),
        lit("system").alias("created_by")
    )
    
    # Write dimension table
    customer_dim_df.write.format("delta").mode("overwrite").saveAsTable(target_table)
    
    return customer_dim_df

def create_event_fact_table(spark, source_table, target_table):
    """Create event fact table with aggregated metrics"""
    
    source_df = spark.table(source_table)
    
    fact_df = source_df.select(
        # Natural keys for dimension lookups
        col("event_id"),
        col("customer_id"),
        date_format(col("event_timestamp"), "yyyy-MM-dd").alias("event_date"),
        
        # Measures
        col("amount"),
        lit(1).alias("event_count"),
        
        # Derived measures
        when(col("amount") > 100, 1).otherwise(0).alias("high_value_flag"),
        
        # Time dimensions
        hour(col("event_timestamp")).alias("event_hour"),
        dayofweek(col("event_timestamp")).alias("event_day_of_week"),
        
        # Audit fields
        col("_processed_at")
    )
    
    # Write fact table partitioned by date for performance
    fact_df.write.format("delta").partitionBy("event_date").mode("append").saveAsTable(target_table)
    
    return fact_df

# Create business-friendly views
def create_gold_views(spark, catalog_schema):
    """Create analytical views for business users"""
    
    # Customer analytics view
    spark.sql(f"""
    CREATE OR REPLACE VIEW {catalog_schema}.vw_customer_analytics AS
    SELECT 
        c.customer_business_key,
        c.customer_name,
        c.customer_segment,
        COUNT(f.event_id) as total_events,
        SUM(f.amount) as total_amount,
        AVG(f.amount) as avg_amount,
        MAX(f.event_date) as last_event_date
    FROM {catalog_schema}.fact_events f
    JOIN {catalog_schema}.dim_customer c 
        ON f.customer_id = c.customer_business_key 
        AND c.is_current = true
    GROUP BY 
        c.customer_business_key, 
        c.customer_name, 
        c.customer_segment
    """)
    
    # Daily metrics view
    spark.sql(f"""
    CREATE OR REPLACE VIEW {catalog_schema}.vw_daily_metrics AS
    SELECT 
        event_date,
        COUNT(event_id) as daily_event_count,
        SUM(amount) as daily_total_amount,
        COUNT(DISTINCT customer_id) as daily_unique_customers,
        AVG(amount) as daily_avg_amount
    FROM {catalog_schema}.fact_events
    GROUP BY event_date
    ORDER BY event_date DESC
    """)

# Example usage
dimensional_model = create_dimensional_model(
    spark=spark,
    source_tables={
        "events": "myproject_catalog_dev.silver.cleaned_events",
        "customers": "myproject_catalog_dev.silver.customer_profiles"
    },
    target_schema="myproject_catalog_dev.gold"
)

create_gold_views(spark, "myproject_catalog_dev.gold")
```

**Performance Optimization**:
- Implement Z-ordering for frequently queried columns
- Configure appropriate partitioning strategies
- Create materialized views for complex aggregations
- Optimize file sizes with Delta Lake optimize operations

### 5. Data Pipeline Orchestration

**Expected orchestration pattern using Databricks Workflows or Azure Data Factory**:

```python
# Main pipeline orchestration notebook
def run_medallion_pipeline(catalog_name, pipeline_date):
    """
    Execute complete medallion pipeline
    
    Args:
        catalog_name: Unity Catalog name
        pipeline_date: Processing date for the pipeline
    """
    
    try:
        # Bronze layer processing
        bronze_results = dbutils.notebook.run(
            "/Shared/notebooks/bronze/ingest_raw_data",
            timeout_seconds=3600,
            arguments={
                "catalog_name": catalog_name,
                "pipeline_date": pipeline_date
            }
        )
        
        # Silver layer processing
        silver_results = dbutils.notebook.run(
            "/Shared/notebooks/silver/clean_and_validate",
            timeout_seconds=3600,
            arguments={
                "catalog_name": catalog_name,
                "pipeline_date": pipeline_date
            }
        )
        
        # Gold layer processing
        gold_results = dbutils.notebook.run(
            "/Shared/notebooks/gold/create_dimensional_model",
            timeout_seconds=3600,
            arguments={
                "catalog_name": catalog_name,
                "pipeline_date": pipeline_date
            }
        )
        
        # Data quality validation
        quality_results = dbutils.notebook.run(
            "/Shared/notebooks/utilities/validate_data_quality",
            timeout_seconds=1800,
            arguments={
                "catalog_name": catalog_name,
                "pipeline_date": pipeline_date
            }
        )
        
        print("Pipeline completed successfully")
        return True
        
    except Exception as e:
        print(f"Pipeline failed: {str(e)}")
        # Send alert notification
        send_pipeline_alert(catalog_name, pipeline_date, str(e))
        return False

# Execute pipeline
success = run_medallion_pipeline("myproject_catalog_dev", "2024-01-15")
```

### 6. Monitoring and Data Quality

**Implement comprehensive monitoring across all layers**:

```python
# Data quality monitoring framework
from great_expectations.checkpoint import SimpleCheckpoint
import json

def setup_data_quality_monitoring(catalog_name):
    """Setup automated data quality monitoring"""
    
    # Define expectations for each layer
    expectations = {
        "bronze": {
            "row_count_check": "expect_table_row_count_to_be_between",
            "freshness_check": "expect_column_max_to_be_between"
        },
        "silver": {
            "completeness_check": "expect_column_to_not_be_null", 
            "validity_check": "expect_column_values_to_be_between"
        },
        "gold": {
            "consistency_check": "expect_column_sum_to_equal",
            "accuracy_check": "expect_column_mean_to_be_between"
        }
    }
    
    # Create validation checkpoints
    for layer, checks in expectations.items():
        create_validation_checkpoint(catalog_name, layer, checks)

def create_validation_checkpoint(catalog_name, layer, checks):
    """Create Great Expectations checkpoint for layer"""
    
    checkpoint_config = {
        "name": f"{catalog_name}_{layer}_validation",
        "config_version": 1.0,
        "template_name": None,
        "module_name": "great_expectations.checkpoint",
        "class_name": "SimpleCheckpoint",
        "run_name_template": f"{layer}_validation_%Y%m%d_%H%M%S",
        "validations": [
            {
                "batch_request": {
                    "datasource_name": "databricks_datasource",
                    "data_connector_name": "default_inferred_data_connector_name",
                    "data_asset_name": f"{catalog_name}.{layer}"
                },
                "expectation_suite_name": f"{layer}_suite"
            }
        ]
    }
    
    return checkpoint_config

# Usage
setup_data_quality_monitoring("myproject_catalog_dev")
```

## Questions for Customization

To provide the most relevant implementation:

1. **Data Sources**: What types of data sources are you working with? (APIs, databases, files, streaming events, etc.)

2. **Business Logic**: What specific business rules and transformations need to be applied in the silver layer?

3. **Analytics Use Cases**: What are the primary analytical use cases and KPIs that the gold layer should support?

4. **Performance Requirements**: What are your expected data volumes and query performance requirements?

5. **Governance**: What data governance, privacy, or compliance requirements do you need to address?

6. **Integration**: Do you need integration with existing BI tools, ML pipelines, or downstream systems?

Based on your answers, I'll customize the implementation with specific code, configurations, and architectural patterns that best fit your requirements while following the proven medallion architecture patterns from enterprise implementations.

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Fill in your project context and requirements
3. Answer the customization questions  
4. Review and adapt the generated code for your specific use case
5. Implement incrementally, testing each layer thoroughly
