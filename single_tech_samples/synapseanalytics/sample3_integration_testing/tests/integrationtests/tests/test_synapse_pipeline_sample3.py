"""Tests for Synapse pipeline"""

import os
from dataconnectors import adls, local_file
from utils import pipelineutils

PIPELINE_NAME = os.getenv("PIPELINE_NAME")
TRIGGER_NAME = os.getenv("TRIGGER_NAME")


def test_synapse_pipeline_succeeded(
    synapse_client, sql_connection, adls_connection_client
):

    # Upload file
    container = os.getenv("ADLS_DESTINATION_CONTAINER")
    filepath = os.getenv("SOURCE_FILE_PATH")
    filename = os.getenv("SOURCE_FILE_NAME")
    processed_container = os.getenv("ADLS_PROCESSED_CONTAINER")

    request_id = adls.upload_to_ADLS(
        adls_connection_client, container, filepath, filename, ""
    )
    pipeline_run_id = pipelineutils.get_pipeline_by_request_id(
        synapse_client, request_id, PIPELINE_NAME, TRIGGER_NAME
    )

    this_run_status = pipelineutils.observe_pipeline(synapse_client, pipeline_run_id)

    processed_parquet_file = adls.read_parquet_file_from_ADLS(
        adls_connection_client, processed_container, f"{pipeline_run_id}.parquet"
    )

    local_processed_parquet_file = local_file.read_parquet_file(
        "files", "processed_parquet_file.parquet"
    )

    assert len(processed_parquet_file) == len(local_processed_parquet_file)

    # Assert
    cursor = sql_connection.cursor()
    cursor.execute(
        f"SELECT * FROM dbo.status WHERE pipeline_run_id='{pipeline_run_id}'"
    )
    row = cursor.fetchone()

    assert row.count == len(local_processed_parquet_file)

    assert this_run_status == "Succeeded"
