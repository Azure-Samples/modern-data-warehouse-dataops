# Known issues, limitations, and workarounds <!-- omit in toc -->

This document lists the known issues and limitations specific to the sample, as well as to Fabric in general. These issues and limitations are based on the current state of the Fabric REST APIs and Fabric deployment pipelines. The document also provides recommendations on how to handle these challenges.

- Issue: For high concurrency (Pipeline) executions, regardless of user's selection the first notebook's execution snapshot is shown and other snapshots cann't be accessed.

    This is a known issue. Here is the workaround:
  
    - Get the end point, workspace id, and artefact id for the notebook under consideration. These are constant for a given notebook and will not change for each execution.
    - From Pipeline execution, go to the execution for the above notebook, click on "output" and from the output copy the run id. Note that each notebook activity might have a different run id - even if all these notebooks are part of the same pipeline execution.
    - Snapshot URL can be obtained like this: `https://{endpoint}/groups/{workspaceId}/synapsenotebooks/{artifactId}/snapshots/{runId}`. Example: `https://app.powerbi.com/groups/aaaa-bbbb-cccc-dddd/synapsenotebooks/zzzz-yyyy-zzxxxd/snapshots/149xxx-yyyy-zzzz`.
    - Open the URL browser to see the snapshot.
