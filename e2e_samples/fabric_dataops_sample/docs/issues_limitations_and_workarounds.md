# Known issues, limitations, and workarounds <!-- omit in toc -->

This document lists the known issues and limitations specific to the sample, as well as to Fabric in general. These issues and limitations are based on the current state of the Fabric REST APIs and Fabric deployment pipelines. The document also provides recommendations on how to handle these challenges.

## Contents <!-- omit in toc -->

- [Incorrect details in Pipeline's snapshot](#incorrect-details-in-pipelines-snapshot)
- [Synthetic Data used in this sample](#synthetic-data-used-in-this-sample)

## Incorrect details in Pipeline's snapshot

For pipeline executions, regardless of the user's selection, the first notebook's execution snapshot is shown, and other snapshots are inaccessible. This is a known issue, and here is a workaround:

    - Get the end point, workspace id, and artefact id for the notebook under consideration. These are constant for a given notebook and will not change for each execution.
    - From Pipeline execution, go to the execution for the above notebook, click on "output" and from the output copy the run id. Note that each notebook activity might have a different run id - even if all these notebooks are part of the same pipeline execution.
    - Snapshot URL can be obtained like this: `https://{endpoint}/groups/{workspaceId}/synapsenotebooks/{artifactId}/snapshots/{runId}`. Example: `https://app.powerbi.com/groups/aaaa-bbbb-cccc-dddd/synapsenotebooks/zzzz-yyyy-zzxxxd/snapshots/149xxx-yyyy-zzzz`.
    - Open the URL browser to see the snapshot.

## Synthetic Data used in this sample

- The data used in this sample is synthetically generated for testing and demonstration purposes within our data pipeline. It is not based on real-world data and may lack logical or practical accuracy for analytical use. Please treat it solely as sample data for validating pipeline functionality rather than for analysis, decision-making, or reporting showcases.
- Each time the data pipeline runs, the same dataset is downloaded into a new subfolder within the landing directory and reprocessed.
- In future iterations of this sample, we plan to introduce more realistic data to demonstrate real world dataengineering scenarios.
