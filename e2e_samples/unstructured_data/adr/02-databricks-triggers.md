# Databricks Trigger Functionality

Proposal

## Context

The Unstructured Data Processing sample will require the setup of a Databricks workflow with individual jobs, each job corresponding to a Jupyter notebook. In order for each of these jobs to be triggered, we can modify the job setup such that each one is triggered when a new file is added to the storage account or a new citation is added to the database.

![Architecture Diagram](../images/application_architecture.drawio.png)

## Decision

The decision is to leverage the [Databricks File Arrival Trigger](https://learn.microsoft.com/en-us/azure/databricks/jobs/file-arrival-triggers#add-a-file-arrival-trigger) for each job, which monitors an external file location (Azure Storage and Azure SQL DB, in our case) on user-defined intervals and executes the job when a new file arrives at that location.

If we are planning to use the Databricks CLI for the initial Databricks setup for a workflow and its jobs, we should modify this command directly, updating the JSON property to something comparable to the following:

```bash
databricks jobs create --json '{
  "name": "My hello notebook job",
  ...
  "trigger": {
    "pause_status": "UNPAUSED",
    "file_arrival": {
      "url": "string",
      "min_time_between_triggers_seconds": 0,
      "wait_after_last_change_seconds": 0
    },
    "periodic": {
      "interval": 0,
      "unit": "HOURS"
    }
  },
}'
```

The option configuration for "wait_after_last_change_seconds" can be used for batch processing of full submissions, as this setting will pause the trigger after initial file arrival until a reasonable length of time has passed for all the files to arrive.

* [What is the Databricks CLI?](https://docs.databricks.com/en/dev-tools/cli/index.html)
* [`databricks jobs create` trigger documentation](https://docs.databricks.com/api/workspace/jobs/create#trigger)

## Consequences

This change removes the prior dependency to locally run the "run experiments" and "evaluate experiments" scripts, as the trigger will automatically do this.

A storage location configured for a file arrival trigger can contain only up to 10,000 files. Locations with more files cannot be monitored for new file arrivals. This entails that the file storage location will need to be manually monitored to ensure this limit is not exceeded.

Another consideration is that only new files trigger runs. Overwriting an existing file with a file of the same name does not trigger a run.
