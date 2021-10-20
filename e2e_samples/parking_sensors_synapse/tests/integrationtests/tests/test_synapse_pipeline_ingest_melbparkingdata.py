"""Tests for Synapse pipeline: process_covid_results"""

import datetime
import time
from azure.identity import ClientSecretCredential
from azure.synapse.artifacts import ArtifactsClient

PIPELINE_NAME = "P_Ingest_MelbParkingData"

def run_and_observe_pipeline(azure_credential: ClientSecretCredential,
                             synapse_endpoint: str, pipeline_name: str,
                             params: dict):
    synapse_client: ArtifactsClient = ArtifactsClient(
        azure_credential, synapse_endpoint)    
    pipeline_run_id = run_pipeline(
        synapse_client, azure_credential, pipeline_name, params)

    print(f'Pipeline run with RunID: {pipeline_run_id}')
    pipeline_run_status = observe_pipeline(synapse_client, pipeline_run_id)

    return pipeline_run_status


def run_pipeline(synapse_client: ArtifactsClient, azure_credential: ClientSecretCredential,
                 pipeline_name: str,
                 params: dict) -> str:
    print('Run pipeline')

    # Debug
    # Get pipeline list of the workspace
    #pipelines = synapse_client.pipeline.get_pipelines_by_workspace()
    pipeline = synapse_client.pipeline.get_pipeline(pipeline_name, if_none_match=None)
    print(pipeline.name)
    print(pipeline.id)


    # Implementation with SDK
    run_pipeliine = synapse_client.pipeline.create_pipeline_run(
        pipeline_name, parameters=params)
    print(run_pipeliine.run_id)

    # Implementation with REST API
    #run_pipeline_url = f'{synapse_endpoint}/pipelines/{pipeline_name}'\
    #    '/createRun?api-version=2020-12-01'
    #access_token = azure_credential.get_token(
    #    'https://dev.azuresynapse.net/.default')
    #headers = {'Authorization': f'Bearer {access_token.token}'}
    #response = requests.post(run_pipeline_url, headers=headers,
    #                         data=json.dumps(params))
    #print(f"response:{response}")
    #pipeline_run_id = response.json()['runId']
    return run_pipeliine.run_id


def observe_pipeline(synapse_client: ArtifactsClient, run_id: str,
                     until_status=["Succeeded", "TimedOut",
                                   "Failed", "Cancelled"],
                     poll_interval=15) -> str:
    print('Observe pipeline')

    pipeline_run_status = ""
    while(pipeline_run_status not in until_status):
        now = datetime.datetime.now()
        print(
            f'{now.strftime("%Y-%m-%d %H:%M:%S")}'
            f' Polling pipeline with run id {run_id}'
            f' for status in {", ".join(until_status)}')

        pipeline_run = synapse_client.pipeline_run.get_pipeline_run(run_id)
        pipeline_run_status = pipeline_run.status
        time.sleep(poll_interval)
    print(
        f'pipeline run id {run_id}'
        f'finished with status {pipeline_run_status}')
    return pipeline_run_status

def test_synapse_pipeline_succeeded(azure_credential, synapse_endpoint, sql_connection):
    """Test that pipeline has data in SQL"""
    this_run = run_and_observe_pipeline(azure_credential, synapse_endpoint, 
        PIPELINE_NAME, params={})  
    # Assert
    cursor = sql_connection.cursor()
    cursor.execute(
        "SELECT COUNT(*) AS COUNT FROM dbo.fact_parking WHERE load_id='{load_id}'"
        .format(load_id=str(this_run.run_id)))
    row = cursor.fetchone()
    assert this_run.status == "Succeeded"
    assert row is not None
    assert int(row.COUNT) >= 1
