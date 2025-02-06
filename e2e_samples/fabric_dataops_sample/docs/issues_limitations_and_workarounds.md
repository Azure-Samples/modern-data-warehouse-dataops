# Known issues, limitations, and workarounds <!-- omit in toc -->

This document lists the known issues and limitations specific to the sample, as well as to Fabric in general. These issues and limitations are based on the current state of the Fabric REST APIs and Fabric deployment pipelines. The document also provides recommendations on how to handle these challenges.

## Contents <!-- omit in toc -->

- [Specific observations](#specific-observations)
  - [Dependencies on `ENVIRONMENT_NAMES` variable](#dependencies-on-environment_names-variable)
  - [Use of synthetic data in the sample](#use-of-synthetic-data-in-the-sample)
- [Limitations](#limitations)
  - [Fabric REST APIs limitations](#fabric-rest-apis-limitations)
- [Known issues](#known-issues)
  - [Fabric environment shown as `uncommitted` after branch-out](#fabric-environment-shown-as-uncommitted-after-branch-out)
    - [Workaround](#workaround)
  - [Incorrect details in pipeline's snapshot](#incorrect-details-in-pipelines-snapshot)
    - [Workaround](#workaround-1)

## Specific observations

### Dependencies on `ENVIRONMENT_NAMES` variable

The sample uses the `ENVIRONMENT_NAMES` variable in the [.env](./../.envtemplate) file to define the environment names. By default, it includes three values: `dev`, `stg`, and `prod`. It's highly recommended to use these values as-is. Additionally, it is recommended to use the same values for branch names as part of the `GIT_BRANCH_NAMES` variable.

If you need to change these values, you may need to update the following:

- The [prepare_azure_repo.sh](./../prepare_azure_repo.sh) script
- The [deploy.sh](./../deploy.sh) script
- The [cleanup.sh](./../cleanup.sh) script
- The [Azure DevOps pipeline](./../devops/templates/pipelines/) YAML files

### Use of synthetic data in the sample

The data used in this sample is synthetically generated for testing and demonstration purposes only. It is not based on real-world data and may lack logical or practical accuracy for analytical use. It should be treated solely as sample data for validating Fabric notebook/pipeline functionality, rather than for analysis, decision-making, or reporting showcases.

Each time the data pipeline runs, the same dataset is downloaded into a new subfolder within the landing directory and reprocessed.

The use of synthetic data helps avoid dependencies on external APIs and safeguards against copyrights issues. In future, we plan to introduce synthetic data generation capabilities within the sample. This feature will allow users to generate realistic data for simulating real-world data engineering scenarios.

## Limitations

### Fabric REST APIs limitations

The support for managed identities and service principals is not available in few of the Fabric REST APIs. The most notable APIs (in context of this sample) that do not support managed identities are:

- [Git APIs](https://learn.microsoft.com/rest/api/fabric/core/git)
- [Data pipelines](https://learn.microsoft.com/en-us/rest/api/fabric/datapipeline/items)

To handle this limitation, the sample requires executing the deployment script twice - once with the managed identity or service principal and once with the user's credentials. The Git integration and data pipeline are created using the user's credentials.

## Known issues

### Fabric environment shown as `uncommitted` after branch-out

After branching-out to a new workspace, the Git status of the Fabric environment in the new workspace is shown as `Uncommitted`. If you open the environment, you will see that the environment does not have the public and custom libraries that were originally uploaded to the dev environment. However, these files are present in the repository.

![Uncommitted environment](./../images/uncommitted-environment.gif)

If you attempt to commit the changes, the libraries in the repository will be deleted. If you try to `undo` the changes, you will receive the notification `Your selected changes were undone`, but the Git status will remain `Uncommitted`.

#### Workaround

To resolve this issue, you need to manually upload the required libraries to the new workspace and publish the changes. Make sure to publish only the libraries related changes and nothing else. With that, you will be able to commit the changes without losing the libraries.

### Incorrect details in pipeline's snapshot

For pipeline executions, regardless of the user's selection, the first notebook's execution snapshot is shown, and other snapshots are inaccessible.

#### Workaround

To view the snapshot of a specific notebook execution, follow these steps:

- Get the end point, workspace id, and artifact id for the notebook under consideration. These are constant for a given notebook and will not change for each execution.
- From Pipeline execution, go to the execution for the above notebook, click on 'output' and from the output copy the `run id`. Note that each notebook activity may have a different value, even if all these notebooks are part of the same pipeline execution.
- Snapshot URL can be obtained like this: `https://{endpoint}/groups/{workspaceId}/synapsenotebooks/{artifactId}/snapshots/{runId}`.
- Open the URL browser to see the snapshot.
