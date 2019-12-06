### Build Pipelines

1. **Build - Quality Assurance**
  - Purpose: Ensure code quality and integrity
  - Trigger: Pull Request to Master
  - Steps:
     1. Build Python packages
     2. Run units tests 
     3. Code Coverage
     4. Linting
2. **Build - Artifacts**
  - Purpose: To produce necessary artifacts for Release
  - Trigger: Commit to Master
  - Steps:
     1. Build and create Python Wheel
     2. Publish artifacts:
        - Python Wheel
        - Databricks Notebooks and cluster configuration
        - Data Factory pipeline definitions
        - IaC - ARM templates, Bash scripts
        - 3rd party library dependencies (JARs, etc)
  
### Release Pipelines

Currently, there is one multi-stage release pipeline with the following stages. Each stage deploys to a different environment.
  
1. **On-demand Integration Testing (QA) environment** - **TODO**
   1. Deploy Azure resources with ARM templates + Bash scripts
   2. Store sensitive configuration information in shared QA KeyVault
   3. Download integration test data from shared Storage to newly deployed ADAL Gen2.
   4. Configure Databricks workspace
      - Setup Data mount
      - Create Databricks secrets
   5. Deploy Data Application to Databricks
      - Deploy cluster given configuration
      - Upload Jars, Python wheels to DBFS
      - Install libraries on cluster
   6. Deploy ADF pipeline
   7. Run integration tests
      - Trigger ADF Pipeline
      - Databricks job to run integration test notebook

2. **Deploy to Staging**
   - NOTE: *Staging environment should be a mirror of Production and thus already have a configured Databricks workspace (secrets, data mount, etc), ADAL Gen2, ADF Pipeline, KeyVault, etc.*
   1. Hydrate data with latest production data
   2. Deploy Data Application to Databricks
      - Deploy cluster given configuration
      - Upload Jars, Python wheels to DBFS
      - Install libraries on cluster
   3. Deploy ADF Pipeline and activate triggers
   4. Run integration tests

3. **Deploy to Production**
   1. Deploy Data Application to Databricks
      - Deploy cluster given configuration
      - Upload Jars, Python wheels to DBFS
      - Install libraries on cluster
   2. Deploy ADF Pipeline
   3. Swap between existing deployment and newly released deployment