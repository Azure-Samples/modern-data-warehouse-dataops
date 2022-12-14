from datetime import datetime, timedelta
import time
from typing import List
from azure.synapse.artifacts import ArtifactsClient
from azure.synapse.artifacts.models._models_py3 import (
    RunQueryFilter,
    RunFilterParameters,
)
import json


def run_and_observe_pipeline(
    synapse_client: ArtifactsClient,
    pipeline_name: str,
    params: dict = None,
) -> str:
    """Create a pipeline run and get the status on completion

    Args:
        synapse_client (ArtifactsClient): Synapse Connection Client
        pipeline_name (str): Name of the Pipeline to run
        params (dict): Parameters for the Synapse Pipeline

    Returns:
        pipeline_run_status (str): Status of the pipeline run
    """
    pipeline_run_id = run_pipeline(synapse_client, pipeline_name, params)
    pipeline_run_status = observe_pipeline(synapse_client, pipeline_run_id)
    return pipeline_run_status


def run_pipeline(
    synapse_client: ArtifactsClient,
    pipeline_name: str,
    params: dict = None,
) -> str:
    """Create a pipeline run and get the run id

    Args:
        synapse_client (ArtifactsClient): Synapse Connection Client
        pipeline_name (str): Name of the Pipeline to run
        params (dict): Parameters for the Synapse Pipeline

    Returns:
        (str): ID of the pipeline run
    """
    print(f'CREATING THE PIPELINE RUN for "{pipeline_name}"...')

    try:
        run_pipeline = synapse_client.pipeline.create_pipeline_run(
            pipeline_name, parameters=params
        )
        pipeline_run_id = run_pipeline.run_id
        print(f'CREATED THE PIPELINE RUN and got the run id "{pipeline_run_id}"')
        return pipeline_run_id
    except Exception as e:
        print(e)
        raise


def observe_pipeline(
    synapse_client: ArtifactsClient,
    run_id: str,
    until_status: List[str] = ["Succeeded", "TimedOut", "Failed", "Cancelled"],
    poll_interval=15,
) -> str:
    """Get the status of the pipeline run

    Args:
        synapse_client (ArtifactsClient): Synapse Connection Client
        run_id (str): ID of the pipeline run
        until_status (List[str]): A list of possible status values that signal completion of the
            pipeline run
        poll_interval (int): The number of seconds to wait before retrying to get the status

    Returns:
        pipeline_run_status (str): ID of the pipeline run
    """
    print(f'GETTING THE PIPELINE RUN STATUS for pipline with run id "{run_id}"...')

    pipeline_run_status = ""

    try:
        while pipeline_run_status not in until_status:
            print(
                f'{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}'
                f" Polling pipeline with run id {run_id}"
                f' for status in {", ".join(until_status)}'
            )
            pipeline_run = synapse_client.pipeline_run.get_pipeline_run(run_id)
            pipeline_run_status = pipeline_run.status
            time.sleep(poll_interval)
        print(
            f'PIPELINE with run id "{run_id}" FINISHED with status "{pipeline_run_status}"'
        )
        return pipeline_run_status
    except Exception as e:
        print(e)
        raise


def get_pipeline_by_request_id(
    synapse_client: ArtifactsClient,
    request_id: str,
    pipeline_name: str,
    trigger_name: str,
    wait_time=10,
) -> str:
    """Get the status of the pipeline run by an ADLS file upload request_id for pipelines
    that are triggered by a storage account upload. A wait time is required since it takes
    time for the file upload to trigger a trigger run/pipeline run.

    Args:
        synapse_client (ArtifactsClient): Synapse Connection Client
        request_id (str): ID of the ADLS upload request
        pipeline_name (str): The name of the pipeline
        trigger_name (str): The name of the trigger
        wait_time (int): The number of seconds to wait before getting the pipeline run

    Returns:
        (str): ID of the pipeline run
    """

    print(f'GETTING PIPELINE "{pipeline_name}" BY TRIGGER REQUEST ID "{request_id}"...')

    # Wait until the Synapse trigger has started
    print(
        f"WAITING {wait_time} seconds to allow the trigger time to start the pipeline..."
    )
    time.sleep(wait_time)

    try:
        # Get a list of the last few trigger runs
        print(f'GETTING the list of trigger runs for Trigger Name "{trigger_name}"...')
        trigger_runs_list = synapse_client.trigger_run.query_trigger_runs_by_workspace(
            filter_parameters=RunFilterParameters(
                filters=[
                    RunQueryFilter(
                        operand="TriggerName",
                        operator="Equals",
                        values=[trigger_name],
                    )
                ],
                last_updated_after=datetime.now() - timedelta(minutes=10),
                last_updated_before=datetime.now(),
            )
        )

        # Search the list of trigger runs for the trigger run associated with the ADLS file upload
        #   request id
        for trigger_run in trigger_runs_list.value:
            print(f'CHECKING for request id "{request_id}" in trigger runs list...')
            if (
                json.loads(trigger_run.properties.get("EventPayload"))
                .get("data")
                .get("requestId")
            ) == (request_id):
                pipeline_run_id = trigger_run.triggered_pipelines.get(pipeline_name)
                print(f'GOT THE TRIGGERED PIPELINE RUN ID "{pipeline_run_id}"')
                return pipeline_run_id

    except Exception as e:
        print(e)
        raise


def get_activity_run_by_pipeline_run_id(
    synapse_client: ArtifactsClient,
    pipeline_name: str,
    pipeline_run_id: str,
    second_pipeline_activity_name: str,
) -> str:
    """Get the id of a pipeline run called by another pipeline by querying a Pipeline Run's
    Activity Runs.

    Args:
        synapse_client (ArtifactsClient): Synapse Connection Client
        pipeline_name (str): The name of the pipeline
        pipeline_run_id (str): The run id of the initial Pipeline Run
        second_pipeline_activity_name (int): The activity name of the pipeline that is called
            within the Pipeline

    Returns:
        (str): ID of the pipeline run
    """

    print(
        f"GETTING the second pipeline run id from pipeline {pipeline_name}"
        f" where the Activity Name is '{second_pipeline_activity_name}'..."
    )

    try:
        # Get a list of the activity runs for the pipeline run
        activity_runs = synapse_client.pipeline_run.query_activity_runs(
            pipeline_name,
            pipeline_run_id,
            filter_parameters=RunFilterParameters(
                filters=[
                    RunQueryFilter(
                        operand="ActivityName",
                        operator="Equals",
                        values=[second_pipeline_activity_name],
                    )
                ],
                last_updated_after=datetime.now() - timedelta(minutes=100),
                last_updated_before=datetime.now(),
            ),
        )

        activity_runs_list = activity_runs.value

        if len(activity_runs_list) > 0:
            # Assume only the pipeline was only called once with that name
            second_pipeline_run_id = activity_runs_list[0].output["pipelineRunId"]
            print(f'GOT second pipeline run id "{second_pipeline_run_id}"')
            return second_pipeline_run_id
        else:
            raise Exception("Cannot find the second pipline that was called.")

    except Exception as e:
        print(e)
        raise
