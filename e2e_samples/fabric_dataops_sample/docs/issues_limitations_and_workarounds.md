# Known issues, limitations, and workarounds <!-- omit in toc -->

This document lists the known issues and limitations specific to the sample, as well as to Fabric in general. These issues and limitations are based on the current state of the Fabric REST APIs and Fabric deployment pipelines. The document also provides recommendations on how to handle these challenges.

## Contents <!-- omit in toc -->

- [Dependencies on `ENVIRONMENT_NAMES` variable](#dependencies-on-environment_names-variable)
- [Incorrect details in Pipeline's snapshot](#incorrect-details-in-pipelines-snapshot)
- [Use of synthetic data in the sample](#use-of-synthetic-data-in-the-sample)

## Dependencies on `ENVIRONMENT_NAMES` variable

The sample uses the `ENVIRONMENT_NAMES` variable in the [.env](./../.envtemplate) file to define the environment names. By default, it includes three values: `dev`, `stg`, and `prod`. It's highly recommended to use these values as-is. Additionally, it is recommended to use the same values for branch names as part of the `GIT_BRANCH_NAMES` variable.

If you need to change these values, you may need to update the following:

- The [prepare_azure_repo.sh](./../prepare_azure_repo.sh) script
- The [deploy.sh](./../deploy.sh) script
- The [cleanup.sh](./../cleanup.sh) script
- The [Azure DevOps pipeline](./../devops/templates/pipelines/) YAML files

## Incorrect details in Pipeline's snapshot

For pipeline executions, regardless of the user's selection, the first notebook's execution snapshot is shown, and other snapshots are inaccessible. This is a known issue, and here is a workaround:

    - Get the end point, workspace id, and artefact id for the notebook under consideration. These are constant for a given notebook and will not change for each execution.
    - From Pipeline execution, go to the execution for the above notebook, click on "output" and from the output copy the run id. Note that each notebook activity might have a different run id - even if all these notebooks are part of the same pipeline execution.
    - Snapshot URL can be obtained like this: `https://{endpoint}/groups/{workspaceId}/synapsenotebooks/{artifactId}/snapshots/{runId}`. Example: `https://app.powerbi.com/groups/aaaa-bbbb-cccc-dddd/synapsenotebooks/zzzz-yyyy-zzxxxd/snapshots/149xxx-yyyy-zzzz`.
    - Open the URL browser to see the snapshot.

## Use of synthetic data in the sample

The data used in this sample is synthetically generated for testing and demonstration purposes only. It is not based on real-world data and may lack logical or practical accuracy for analytical use. It should be treated solely as sample data for validating Fabric notebook/pipeline functionality, rather than for analysis, decision-making, or reporting showcases.

Each time the data pipeline runs, the same dataset is downloaded into a new subfolder within the landing directory and reprocessed.

The use of synthetic data helps avoid dependencies on external APIs and safeguards against copyrights issues. In future, we plan to introduce synthetic data generation capabilities within the sample. This feature will allow users to generate realistic data for simulating real-world data engineering scenarios.
