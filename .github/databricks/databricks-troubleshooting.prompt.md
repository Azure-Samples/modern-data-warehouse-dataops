# Databricks Troubleshooting Assistant

Use this prompt to help diagnose and resolve common issues in Azure Databricks projects with Unity Catalog.

---

**Prompt for GitHub Copilot:**

You are an Azure Databricks troubleshooting expert with extensive experience resolving issues in enterprise environments. Help me diagnose and resolve problems in my Databricks project based on proven troubleshooting patterns from production implementations.

## My Current Issue

**Issue Description**: [Describe the specific problem you're experiencing]

**Environment**: [Development/Staging/Production]

**When it Started**: [When did this issue first appear?]

**Error Messages**: [Copy any specific error messages you're seeing]

**Recent Changes**: [Any recent deployments, configuration changes, or code updates]

**Impact**: [What functionality is affected? How many users/processes?]

## Common Issue Categories

Please help me troubleshoot issues in one of these categories:

### 1. Unity Catalog Issues

**Permission and Access Problems**:
```sql
-- Common Unity Catalog errors and solutions

-- Error: "Permission denied: User does not have USE CATALOG on catalog 'catalog_name'"
-- Diagnosis: Check catalog permissions
SHOW GRANTS ON CATALOG catalog_name;

-- Solution: Grant appropriate permissions
GRANT USE CATALOG ON CATALOG catalog_name TO `user@company.com`;
GRANT CREATE SCHEMA ON CATALOG catalog_name TO `data_engineers`;

-- Error: "External location does not exist or is not accessible"
-- Diagnosis: Check external location configuration
DESCRIBE EXTERNAL LOCATION location_name;

-- Solution: Verify storage credential and path
CREATE EXTERNAL LOCATION my_location 
URL 'abfss://container@storage.dfs.core.windows.net/path'
WITH (STORAGE_CREDENTIAL my_credential);
```

**Metastore Configuration Issues**:
```python
# Diagnostic queries for metastore issues
import requests
import json

def diagnose_metastore_issues(workspace_url, token):
    """
    Comprehensive metastore diagnostics
    """
    headers = {'Authorization': f'Bearer {token}'}
    
    # Check metastore assignment
    response = requests.get(
        f'{workspace_url}/api/2.1/unity-catalog/current-metastore-assignment',
        headers=headers
    )
    
    if response.status_code != 200:
        print(f"❌ Metastore assignment issue: {response.text}")
        return False
    
    metastore_info = response.json()
    print(f"✅ Metastore: {metastore_info.get('metastore_id')}")
    
    # Check storage credentials
    creds_response = requests.get(
        f'{workspace_url}/api/2.1/unity-catalog/storage-credentials',
        headers=headers
    )
    
    if creds_response.status_code == 200:
        creds = creds_response.json().get('storage_credentials', [])
        print(f"✅ Storage credentials found: {len(creds)}")
        for cred in creds:
            print(f"  - {cred['name']}: {cred.get('azure_managed_identity', {}).get('access_connector_id', 'N/A')}")
    else:
        print(f"❌ Storage credentials issue: {creds_response.text}")
    
    return True

# Usage
diagnose_metastore_issues("https://adb-123456.azuredatabricks.net", "your-token")
```

### 2. Cluster and Performance Issues

**Cluster Startup Failures**:
```python
# Cluster diagnostic script
def diagnose_cluster_issues(cluster_id, databricks_client):
    """
    Diagnose cluster startup and performance issues
    """
    from databricks_cli.clusters.api import ClustersApi
    
    clusters_api = ClustersApi(databricks_client)
    
    # Get cluster info
    cluster_info = clusters_api.get_cluster(cluster_id)
    cluster_state = cluster_info.get('state', 'UNKNOWN')
    
    print(f"Cluster State: {cluster_state}")
    
    if cluster_state == 'ERROR':
        print("❌ Cluster in ERROR state")
        
        # Check termination reason
        termination_reason = cluster_info.get('termination_reason', {})
        print(f"Termination Reason: {termination_reason}")
        
        # Common solutions
        if 'INSTANCE_UNREACHABLE' in str(termination_reason):
            print("💡 Solution: Instance type may be unavailable in region")
            print("   - Try different instance type")
            print("   - Check regional capacity")
            
        elif 'INSTANCE_POOL_NOT_READY' in str(termination_reason):
            print("💡 Solution: Instance pool issue")
            print("   - Check instance pool configuration")
            print("   - Verify instance pool capacity")
    
    # Check driver logs for specific errors
    try:
        driver_logs = clusters_api.get_cluster_log_delivery(cluster_id)
        print(f"✅ Driver logs available: {driver_logs}")
    except Exception as e:
        print(f"❌ Cannot access driver logs: {e}")
    
    # Performance diagnostics
    spark_version = cluster_info.get('spark_version', '')
    node_type = cluster_info.get('node_type_id', '')
    num_workers = cluster_info.get('num_workers', 0)
    
    print(f"\nCluster Configuration:")
    print(f"  Spark Version: {spark_version}")
    print(f"  Node Type: {node_type}")
    print(f"  Workers: {num_workers}")
    
    # Performance recommendations
    if 'i3' in node_type.lower():
        print("💡 Performance Tip: Using i3 instances - good for I/O intensive workloads")
    elif 'r5' in node_type.lower():
        print("💡 Performance Tip: Using r5 instances - good for memory intensive workloads")
    
    if num_workers == 0:
        print("⚠️  Warning: Single-node cluster - consider adding workers for better performance")
```

**Memory and Resource Issues**:
```python
# Memory optimization diagnostics
def diagnose_memory_issues(spark):
    """
    Diagnose and resolve memory-related issues
    """
    # Check current Spark configuration
    spark_conf = spark.sparkContext.getConf().getAll()
    
    print("Current Spark Configuration:")
    memory_configs = [conf for conf in spark_conf if 'memory' in conf[0].lower()]
    for config in memory_configs:
        print(f"  {config[0]}: {config[1]}")
    
    # Check executor memory usage
    executor_infos = spark.sparkContext.statusTracker().getExecutorInfos()
    
    print(f"\nExecutor Information:")
    for executor in executor_infos:
        print(f"  Executor {executor.executorId}:")
        print(f"    Max Memory: {executor.maxMemory / (1024**3):.2f} GB")
        print(f"    Memory Used: {executor.memoryUsed / (1024**3):.2f} GB")
        print(f"    Active Tasks: {executor.activeTasks}")
    
    # Memory optimization recommendations
    driver_memory = spark.conf.get('spark.driver.memory', '1g')
    executor_memory = spark.conf.get('spark.executor.memory', '1g')
    
    print(f"\n💡 Current Memory Settings:")
    print(f"  Driver Memory: {driver_memory}")
    print(f"  Executor Memory: {executor_memory}")
    
    # Recommendations based on workload patterns
    print(f"\n💡 Memory Optimization Tips:")
    print("  - For large datasets: Increase executor memory")
    print("  - For wide transformations: Increase shuffle partition count")
    print("  - For broadcast joins: Increase driver memory")
    print("  - Consider using cache() for frequently accessed DataFrames")

# Usage in notebook
diagnose_memory_issues(spark)
```

### 3. Data Pipeline Failures

**Bronze Layer Issues**:
```python
# Bronze layer troubleshooting
def diagnose_bronze_issues(source_path, target_table, spark):
    """
    Diagnose common bronze layer ingestion issues
    """
    print(f"Diagnosing bronze ingestion: {source_path} → {target_table}")
    
    try:
        # Check source data accessibility
        source_files = dbutils.fs.ls(source_path)
        print(f"✅ Source files found: {len(source_files)}")
        
        if len(source_files) == 0:
            print("❌ No source files found")
            print("💡 Solutions:")
            print("  - Check data pipeline upstream")
            print("  - Verify source system is producing data")
            print("  - Check file path and permissions")
            return False
        
        # Sample a small amount of data
        sample_df = spark.read.option("multiline", "true").json(source_path).limit(10)
        sample_count = sample_df.count()
        
        if sample_count == 0:
            print("❌ Source files are empty or unreadable")
            print("💡 Solutions:")
            print("  - Check file format compatibility")
            print("  - Verify file permissions")
            print("  - Check for corrupted files")
            return False
        
        print(f"✅ Sample data readable: {sample_count} records")
        
        # Check schema consistency
        sample_df.printSchema()
        
        # Check for common data quality issues
        null_counts = {}
        for column in sample_df.columns:
            null_count = sample_df.filter(sample_df[column].isNull()).count()
            if null_count > 0:
                null_counts[column] = null_count
        
        if null_counts:
            print(f"⚠️  Columns with null values: {null_counts}")
        
        # Check target table if exists
        if spark.catalog.tableExists(target_table):
            target_df = spark.table(target_table)
            target_count = target_df.count()
            print(f"✅ Target table exists with {target_count} records")
            
            # Check for recent data
            if '_ingested_at' in target_df.columns:
                latest_ingestion = target_df.agg({"_ingested_at": "max"}).collect()[0][0]
                print(f"Latest ingestion: {latest_ingestion}")
        else:
            print("ℹ️  Target table does not exist - will be created on first run")
        
        return True
        
    except Exception as e:
        print(f"❌ Bronze diagnosis failed: {str(e)}")
        print("💡 Solutions:")
        print("  - Check Unity Catalog permissions")
        print("  - Verify storage account access")
        print("  - Check external location configuration")
        return False

# Usage
diagnose_bronze_issues(
    "abfss://raw@storage.dfs.core.windows.net/data/*.json",
    "catalog.bronze.raw_events",
    spark
)
```

**Silver Layer Issues**:
```python
# Silver layer troubleshooting
def diagnose_silver_issues(source_table, target_table, spark):
    """
    Diagnose silver layer processing issues
    """
    print(f"Diagnosing silver processing: {source_table} → {target_table}")
    
    try:
        # Check source table
        source_df = spark.table(source_table)
        source_count = source_df.count()
        print(f"✅ Source table: {source_count} records")
        
        if source_count == 0:
            print("❌ Source table is empty")
            print("💡 Check bronze layer ingestion")
            return False
        
        # Check data quality issues
        print("\nData Quality Analysis:")
        
        # Check for null values in key columns
        key_columns = ['id', 'timestamp', 'customer_id']  # Adjust based on your schema
        for column in key_columns:
            if column in source_df.columns:
                null_count = source_df.filter(source_df[column].isNull()).count()
                null_pct = (null_count / source_count) * 100
                print(f"  {column}: {null_count} nulls ({null_pct:.1f}%)")
                
                if null_pct > 10:
                    print(f"    ⚠️  High null percentage in {column}")
        
        # Check for duplicates
        if 'id' in source_df.columns:
            distinct_count = source_df.select('id').distinct().count()
            duplicate_count = source_count - distinct_count
            if duplicate_count > 0:
                print(f"  ⚠️  Found {duplicate_count} duplicate records")
        
        # Check data types
        print(f"\nSchema validation:")
        source_df.printSchema()
        
        # Test transformation logic on sample
        sample_df = source_df.limit(1000)
        
        # Apply silver transformation (you would import your actual function)
        # transformed_df = your_silver_transformation_function(sample_df)
        # print(f"✅ Transformation successful on sample data")
        
        return True
        
    except Exception as e:
        print(f"❌ Silver diagnosis failed: {str(e)}")
        
        # Common silver layer issues
        if "Column" in str(e) and "does not exist" in str(e):
            print("💡 Column mapping issue - check schema evolution")
        elif "cannot resolve" in str(e).lower():
            print("💡 SQL reference issue - check column names and table references")
        elif "Data type mismatch" in str(e):
            print("💡 Data type conversion issue - check casting logic")
        
        return False

# Usage
diagnose_silver_issues("catalog.bronze.raw_events", "catalog.silver.cleaned_events", spark)
```

### 4. Authentication and Security Issues

**Service Principal Issues**:
```python
# Service principal diagnostics
def diagnose_service_principal_issues():
    """
    Diagnose service principal authentication issues
    """
    import os
    import requests
    
    print("Diagnosing Service Principal Authentication...")
    
    # Check environment variables
    required_vars = ['AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID']
    missing_vars = [var for var in required_vars if not os.environ.get(var)]
    
    if missing_vars:
        print(f"❌ Missing environment variables: {missing_vars}")
        print("💡 Solution: Set required environment variables")
        return False
    
    client_id = os.environ.get('AZURE_CLIENT_ID')
    client_secret = os.environ.get('AZURE_CLIENT_SECRET')
    tenant_id = os.environ.get('AZURE_TENANT_ID')
    
    # Test Azure AD token acquisition
    try:
        token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
        token_payload = {
            'grant_type': 'client_credentials',
            'client_id': client_id,
            'client_secret': client_secret,
            'scope': 'https://storage.azure.com/.default'
        }
        
        response = requests.post(token_url, data=token_payload)
        
        if response.status_code == 200:
            print("✅ Service principal authentication successful")
            token_data = response.json()
            print(f"Token expires in: {token_data.get('expires_in')} seconds")
            return True
        else:
            print(f"❌ Token acquisition failed: {response.text}")
            print("💡 Solutions:")
            print("  - Verify client ID and secret")
            print("  - Check service principal permissions")
            print("  - Verify tenant ID")
            return False
            
    except Exception as e:
        print(f"❌ Authentication test failed: {str(e)}")
        return False

# Unity Catalog permissions check
def check_unity_catalog_permissions(catalog_name, spark):
    """
    Check Unity Catalog permissions for current user
    """
    try:
        # Check catalog access
        spark.sql(f"USE CATALOG {catalog_name}")
        print(f"✅ Can access catalog: {catalog_name}")
        
        # List schemas
        schemas = spark.sql(f"SHOW SCHEMAS IN {catalog_name}").collect()
        print(f"✅ Found {len(schemas)} schemas")
        
        # Check specific permissions
        grants = spark.sql(f"SHOW GRANTS ON CATALOG {catalog_name}").collect()
        print(f"Current grants on {catalog_name}:")
        for grant in grants:
            print(f"  {grant.principal}: {grant.action_type}")
        
        return True
        
    except Exception as e:
        print(f"❌ Permission check failed: {str(e)}")
        
        if "Permission denied" in str(e):
            print("💡 Solutions:")
            print("  - Request catalog access from admin")
            print("  - Check if correct catalog name is used")
            print("  - Verify Unity Catalog setup")
        
        return False

# Usage
diagnose_service_principal_issues()
check_unity_catalog_permissions("my_catalog", spark)
```

### 5. Network and Connectivity Issues

**Private Endpoint Connectivity**:
```python
# Network connectivity diagnostics
def diagnose_network_connectivity():
    """
    Diagnose network connectivity issues
    """
    import subprocess
    import socket
    
    print("Diagnosing Network Connectivity...")
    
    # Test storage account connectivity
    storage_endpoints = [
        "myaccount.blob.core.windows.net",
        "myaccount.dfs.core.windows.net"
    ]
    
    for endpoint in storage_endpoints:
        try:
            # Test DNS resolution
            ip = socket.gethostbyname(endpoint)
            print(f"✅ DNS resolution for {endpoint}: {ip}")
            
            # Test port connectivity
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((endpoint, 443))
            sock.close()
            
            if result == 0:
                print(f"✅ Port 443 connectivity to {endpoint}")
            else:
                print(f"❌ Cannot connect to {endpoint}:443")
                print("💡 Check private endpoint configuration")
            
        except Exception as e:
            print(f"❌ Connectivity test failed for {endpoint}: {e}")
    
    # Test Databricks connectivity
    try:
        databricks_url = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiUrl().get()
        print(f"✅ Databricks workspace URL: {databricks_url}")
    except:
        print("❌ Cannot determine Databricks workspace URL")

# VNet integration check
def check_vnet_integration():
    """
    Check VNet integration status
    """
    try:
        # Check if running in VNet-integrated workspace
        network_info = spark.sql("SELECT * FROM current_metastore()").collect()
        print("✅ Successfully queried metastore - VNet integration working")
        
        # Check subnet configuration
        cluster_info = dbutils.notebook.entry_point.getDbutils().notebook().getContext().tags().get("clusterId")
        print(f"Cluster ID: {cluster_info}")
        
    except Exception as e:
        print(f"❌ VNet integration check failed: {e}")
        print("💡 Solutions:")
        print("  - Verify NSG rules allow Databricks traffic")
        print("  - Check UDR configuration")
        print("  - Ensure proper subnet delegation")

# Usage
diagnose_network_connectivity()
check_vnet_integration()
```

### 6. Job and Workflow Failures

**Databricks Job Diagnostics**:
```python
# Job failure diagnostics
def diagnose_job_failures(job_id, databricks_client):
    """
    Diagnose Databricks job failures
    """
    from databricks_cli.jobs.api import JobsApi
    from databricks_cli.runs.api import RunsApi
    
    jobs_api = JobsApi(databricks_client)
    runs_api = RunsApi(databricks_client)
    
    # Get recent runs
    runs = runs_api.list_runs(job_id=job_id, limit=10)
    
    print(f"Recent runs for job {job_id}:")
    
    failed_runs = []
    for run in runs.get('runs', []):
        run_id = run['run_id']
        state = run.get('state', {})
        result_state = state.get('result_state', 'UNKNOWN')
        start_time = run.get('start_time', 0) / 1000
        
        print(f"  Run {run_id}: {result_state} (Started: {start_time})")
        
        if result_state in ['FAILED', 'TIMEDOUT', 'CANCELLED']:
            failed_runs.append(run_id)
    
    # Analyze failed runs
    for run_id in failed_runs[:3]:  # Analyze last 3 failed runs
        print(f"\nAnalyzing failed run {run_id}:")
        
        try:
            run_output = runs_api.get_run_output(run_id)
            
            if 'error' in run_output:
                error_msg = run_output['error']
                print(f"❌ Error: {error_msg}")
                
                # Common error patterns and solutions
                if "OutOfMemoryError" in error_msg:
                    print("💡 Solution: Increase cluster memory or optimize query")
                elif "FileNotFoundException" in error_msg:
                    print("💡 Solution: Check file paths and data availability")
                elif "AnalysisException" in error_msg:
                    print("💡 Solution: Check SQL syntax and table/column names")
                elif "Permission denied" in error_msg:
                    print("💡 Solution: Check Unity Catalog permissions")
            
            if 'logs' in run_output:
                logs = run_output['logs']
                print(f"📋 Logs available: {len(logs)} characters")
                
                # Extract key information from logs
                if "Exception" in logs:
                    lines = logs.split('\n')
                    exception_lines = [line for line in lines if 'Exception' in line]
                    for line in exception_lines[:5]:
                        print(f"  Exception: {line.strip()}")
        
        except Exception as e:
            print(f"Could not retrieve run output: {e}")

# Usage
# diagnose_job_failures(12345, databricks_client)
```

## Diagnostic Commands Reference

### Quick Diagnostic Commands

```sql
-- Unity Catalog diagnostics
SHOW CATALOGS;
SHOW GRANTS ON CATALOG catalog_name;
DESCRIBE EXTERNAL LOCATION location_name;
SHOW STORAGE CREDENTIALS;

-- Table diagnostics
DESCRIBE DETAIL table_name;
SHOW PARTITIONS table_name;
ANALYZE TABLE table_name COMPUTE STATISTICS;

-- Performance diagnostics
EXPLAIN EXTENDED SELECT * FROM table_name;
SHOW TABLE EXTENDED LIKE 'table_name';
```

```python
# Spark diagnostics
# Check configuration
spark.conf.get("spark.sql.adaptive.enabled")
spark.conf.get("spark.serializer")

# Check metrics
spark.sparkContext.statusTracker().getExecutorInfos()
spark.sparkContext.getConf().getAll()

# Check storage
dbutils.fs.ls("/mnt/")
dbutils.fs.head("/path/to/file")
```

## Emergency Response Playbook

### Critical Production Issues

1. **Immediate Assessment**:
   - Identify affected users/processes
   - Determine data integrity impact
   - Check if issue is spreading

2. **Quick Fixes**:
   - Restart failed jobs
   - Scale up cluster resources
   - Switch to backup data sources

3. **Communication**:
   - Notify stakeholders
   - Update status page
   - Document timeline

4. **Root Cause Analysis**:
   - Collect logs and metrics
   - Reproduce in non-prod
   - Implement permanent fix

## Questions for Targeted Help

To provide the most relevant troubleshooting assistance:

1. **What specific error are you seeing?** (Include full error message)

2. **When did this issue start?** (After deployment, configuration change, etc.)

3. **What environment?** (Development, staging, production)

4. **What was the last successful operation?** (Helps identify what changed)

5. **What troubleshooting have you already tried?**

6. **How urgent is this issue?** (Affects prioritization of solutions)

Based on your specific situation, I'll provide targeted diagnostic steps, likely root causes, and step-by-step resolution procedures using proven troubleshooting patterns from enterprise Databricks implementations.

---

**Usage Instructions:**
1. Copy this prompt to GitHub Copilot Chat
2. Describe your specific issue in detail
3. Follow the diagnostic steps provided
4. Implement the recommended solutions
5. Document the resolution for future reference
