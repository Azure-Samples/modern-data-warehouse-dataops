# Known issues, limitations, and workarounds <!-- omit in toc -->

This document lists the known issues and limitations specific to the sample, as well as to Fabric in general. These issues and limitations are based on the current state of the Fabric REST APIs and Fabric deployment pipelines. The document also provides recommendations on how to handle these challenges.

## Contents <!-- omit in toc -->

- [Infrastructure deployment related](#infrastructure-deployment-related)
- [Code/Pipeline execution related](#codepipeline-execution-related)
  - [Issue: For high concurrency (Pipeline) executions, regardless of user's selection the first notebook's execution snapshot is shown and other snapshots can't be accessed](#issue-for-high-concurrency-pipeline-executions-regardless-of-users-selection-the-first-notebooks-execution-snapshot-is-shown-and-other-snapshots-cant-be-accessed)

### Infrastructure deployment related

### Code/Pipeline execution related

#### Issue: For high concurrency (Pipeline) executions, regardless of user's selection the first notebook's execution snapshot is shown and other snapshots can't be accessed

    - Get the end point, workspace id, and artefact id for the notebook under consideration. These are constant for a given notebook and will not change for each execution.
    - From Pipeline execution, go to the execution for the above notebook, click on "output" and from the output copy the run id. Note that each notebook activity might have a different run id - even if all these notebooks are part of the same pipeline execution.
    - Snapshot URL can be obtained like this: `https://{endpoint}/groups/{workspaceId}/synapsenotebooks/{artifactId}/snapshots/{runId}`. Example: `https://app.powerbi.com/groups/aaaa-bbbb-cccc-dddd/synapsenotebooks/zzzz-yyyy-zzxxxd/snapshots/149xxx-yyyy-zzzz`.
    - Open the URL browser to see the snapshot.
