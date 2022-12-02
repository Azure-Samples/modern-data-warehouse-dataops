"""Tests for Synapse pipeline: process_covid_results"""

import datetime
import time
import os
from azure.identity import ClientSecretCredential
from azure.synapse.artifacts import ArtifactsClient
from dataconnectors import adls
from utils import pipelineutils

PIPELINE_NAME = os.getenv("PIPELINE_NAME")
TRIGGER_NAME = os.getenv("TRIGGER_NAME")


def test_synapse_pipeline_succeeded(azure_credential, synapse_client, sql_connection, synapse_status_poll_interval, adls_connection_client):

    # Upload file
    container = os.getenv("ADLS_DESTINATION_CONTAINER")
    filename = os.getenv("SOURCE_FILE_NAME")

    request_id = adls.upload_to_ADLS(adls_connection_client, container, filename, "")
    pipeline_run_id = pipelineutils.get_pipeline_by_request_id(synapse_client, request_id, PIPELINE_NAME, TRIGGER_NAME)
    this_run_status = pipelineutils.observe_pipeline(synapse_client, pipeline_run_id)

    # adls.download_from_ADLS() TODO

    # Assert
    # cursor = sql_connection.cursor()
    # cursor.execute(
    #     "SELECT COUNT(*) AS COUNT FROM dbo.fact_parking WHERE load_id='{load_id}'"
    #     .format(load_id=this_run_id))
    # row = cursor.fetchone()
    assert this_run_status == "Succeeded"
    # assert row is not None
    # # In some rare scenarios, it might so happen that the dataset gets aggregated but still manages to produce one row.
    # # For avoiding such an edge case, the assertion is checking for more than one row.
    # assert int(row.COUNT) > 1
