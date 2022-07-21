# Title: Where to land Parking Sensor (Synapse) in repo

## Status

Accepted.

## Context

We are beginning to port the Parking Sensor solution to use Azure Synapse instead of Azure Databricks. We need to decide on where and how this new Parking Sensor (Synapse) solution will reside on the larger DataOps repository.

## Considerations

- Reduce code and documentation duplication. Reuse where reasonable.
- End-user experience of using the sample.
- Reduce confusion and developer experience.

## Options

### Option 1: Keep current structure

This builds on the existing work of the Parking Sensor E2E sample and incorporating the Synapse-specific code into the existing code base.

**End-user experience to deploy sample:**

Run the existing `./deploy.sh` and prompt for choice of `databricks` or `synapse`. Alternatively, have them set a required environment variable (ei. `FLAVOUR`) to determine which sample to deploy. User will then need to follow a set of required manual steps specific to each sample.

**Pros**:

- Not changing existing structure with minimal refactor needed.
- Can reuse existing code and components which are the same (or very similar) between the samples:
  - `data` - raw seed data
  - `devops` - AzDO job templates and pipelines
    - `azure-pipelines-ci-qa-sql.yml` - Runs SQL DACPAC build as part of PR.
    - `azure-pipelines-ci-qa-python.yml` - Run python package unit tests as part of PR.
    - `deploy-dedicated-sql-pool-job.yml` - template to deploy SQL DACPAC
    - *Partly* `integration-tests-job.yml` - template to run integration tests, calls pytest. Environment variables passed to pytest will differ between Synapse and Databricks.
  - `sql` - SSDT Visual Studio Project that creates the SQL DACPAC
  - `src/ddo_transform` - Python package source code that produces the wheel file
  - `infrastructure/modules` - Bicep modules of shared infrastructure components.
    - `appinsights.bicep`
    - `keyvault.bicep`
    - `log_analytics.bicep`
    - `storage.bicep`
  - `scripts` - Deploy scripts
    - `deploy_azdo_service_connections_azure.sh` - deploys AzDO service connection.
    - `deploy_azdo_service_connections_github.sh` - deploys AzDO github connection.
    - *Partly* `deploy_infrastructure.sh` - deploys all infrastructure. The reuse will be from deployment of shared components (ei. appinsights, storage, log analytics).
    - *Partly* `deploy_azdo_pipelines.sh` - reuse of `create_pipeline` function
    - `clean-up.sh` - deletes Azure and AzDO resources given deploy prefix.
    - `init_environment.sh` - checks of require variables are set.
    - `verify_prerequisites.sh` - checks if system requirements are set.
  - `reports` - PowerBI report
  - `.devcontainer`
  - `README` - parts of the main README applicable to both (ei. Key Learnings)
- Conventions such as naming, deploy-prefix, unique deploy-id suffix, are already used across the sample and will be easier to adopt.

**Cons**:

- Requires familiarization period with the existing code base with some initial confusion from developers not familiar with the Parking Sensor E2E code base.
- Because the codebase is mixed, it maybe which artifacts are specific to one sample flavour or the other by the end user.

### Option 2: Single E2E sample, but have a common folder

This proposes the following structure, having a `common` folder containing shared assets.

```text
/parking_sensors
  /common
  /databricks
  /synapse
```

**End-user experience to deploy sample:**

Exactly the same as **Option 1**.

**Pros**:

- Reuse of components as outlined in **Option 1**.
- Very clear which artifacts belong to which sample (Synapse vs Databricks) and which are shared.

**Cons**:

- It will need considerable effort to retest existing codebase due to the major refactor needed to move to this new structure.

### Option 3: Completely separate E2E Samples

This proposes a completely new E2E sample with no common artifacts and reuse of the existing Parking Sensor sample.

```text
/e2e_samples
  /parking_sensors
  /parking_sensors_synapse
```

**End-user experience to deploy sample:**

Since this proposes a completely new sample, the end-user experience will be specific to that sample. User will deploy each sample as per instruction of each sample. No changes to Parking Sensor E2E sample deployment experience.

**Pros**:

- Completely separate sample allows for a blank canvas of the developers with no need to familiarize with an existing codebase.
- Very clear which artifacts belong to which sample as they are completely separate.

**Cons**:

- No reuse of existing work which will result in code duplication across the two samples.
- Higher maintainance cost as now need to maintain two similar samples with duplicate code.

## Decision

After discussion with crew, the majority opted for Option 3 for the immediate short-term with the potential to move the structure to Option 2 for the medium to longterm.

## Consequences

- Acceptance of duplication of code between the two samples.
- Potential to improve how original Parking Sensor codebase is structured.
- Existing work needs to be ported (copied) over.
