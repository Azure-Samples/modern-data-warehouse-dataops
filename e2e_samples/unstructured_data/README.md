# Unstructured Data Processing  <!-- omit in toc -->

This is a reference implementation of an end to end data pipeline for processing unstructured data. The high level goal of this implementation is to:

- Ingest unstructured data as pdf documents
- Use Azure AI Services to extract and evaluate text data
- Enable human in the look feedback with a the citation tool
- Serve the data for a RAG application

As a reference implementation, this should serve as an experiment to deploy in a sandbox or dev environment to explore capabilities.

## Contents <!-- omit in toc -->

- [Architecture](#architecture)
- [Deploy Script Resources](#deploy-script-resources)
- [How to use the sample](#how-to-use-the-sample)
  - [Applying the Database Schema](#applying-the-database-schema)
  - [Popluate the database](#popluate-the-database)
  - [Adding input data into Storage Account](#adding-input-data-into-storage-account)
  - [Running notebooks in Databricks](#running-notebooks-in-databricks)
- [Cleaning up](#cleaning-up)

## Architecture

![Application Architecture](images/application_architecture.drawio.png)

## Deploy Script Resources

 The following resources are created within a net new resource group when the deploy script is run:

- Azure Databricks Service
- Azure storage account
- Key vault
- SQL Server
- SQL Database
- App Service
- Web App
- Function App
- Event Grid System Topic (delete this)

A secondary Databricks-managed resource group is likewise created with the following resources:

- Managed Identity
- Storage account
- NAT gateway
- Public IP address
- Access Connector for Azure Databricks
- Network security group
- Virtual network

The following non-resources are also created:

- Entra ID Security Group containing the user

## How to use the sample

```bash
cd e2e_samples/unstructured_data

cp .envtemplate .env

# stop
# fill in .env with your required variables
# then
chmod +x ./deploy.sh

bash deploy.sh
```

### Applying the Database Schema

The above deploy script should add you to a security group used as the admin for the newly created SQL DB.

To apply the database schema, follow these steps:

1. Clone the [excitation tool](https://github.com/billba/excitation/tree/main) repository, and navigate to `reference-azure-backend/functions`.
2. Follow the README steps around locally running the Azure Function, being sure to plug in the newly created `SQL_DATABASE_NAME`, `SQL_SERVER_NAME` (only the portion preceding ".database.windows.net"), `BLOB_STORAGE_ACCOUNT_NAME`, and `BLOB_STORAGE_ACCOUNT_KEY` environment variables to the `local.settings.json` file. Ensure that the `SQL_DATABASE_SYNC` is set to `true`.
3. Run `npm install` and `npm start` from your terminal to locally run the Azure Function.
4. Navigate to your SQL database's Query Editor and confirm creation of all tables listed under the `reference-azure-backend/functions/src/entity` folder.

### Popluate the database

Before generating citations and writing to the database, the database must be populated with a template and questions. In the database, citations have a question ID which means the question must first exist in the database in order to create a citation. Likwise, a question has a template ID. Follow the steps below to popluate the database with a template and the questions provided in the sample:

1. Ensure environment variables are set for the citation db.
2. Run `python ./scripts/populate_db.py`
3. This will create a file called `data/template_<template-id>.lock.yaml`. This will contain the question IDs needed to write to the database
4. Update the question variant YAML definitions with the apporiate db_question_id at [total_revenue](../unstructured_data/src/experiments/llm_citation_generator/config/questions/total_revenue/base-config.yaml) and [earnings_per_share](../unstructured_data/src/experiments/llm_citation_generator/config/questions/earnings_per_share/base-config.yaml).

```yaml
init_args:
  db_question_id: <question_id>
```

### Adding input data into Storage Account

Two containers are created as a part of the infra setup in the storage account: `input-documents` and `di-results`.
Input documents should be placed in container `input-documents` and organized in folders.
`di-results` container will be auto-populated by the code at a later stage.

### Running notebooks in Databricks

1. Open the Databricks instance that was created as part of deployment script
2. In `shared` folder of the workspace find the notebook `e2e_samples/unstructured_data/scripts/run_experiments.ipynb`
3. Copy `.envtemplate` and renaming into `.env`
4. Set values in `.env`
5. Update `data/test-data.jsonl` with paths to the folders in Storage Account
6. Update `src/experiments/llm_citation_generator/config/questions/total_revenue/base-config.yaml` with id of the question (should be 1). See [populate the db](#popluate-the-database)
7. Whitelist Databricks IP in SQL server networking settings
8. Run the notebook using the cluster that was created as part of deployment
9. To run the evaluation notebook (`e2e_samples/unstructured_data/scripts/evaluate_experiments.ipynb`) get the id of the experiment run from the experiment run output and update the value of `run_id`

## Cleaning up

TODO: Destroy steps
