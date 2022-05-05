
PIPELINE_NAME = "IngestToBronze"
SINK_CONTAINER = "datalake"
FILE_PATH = "bronze/"
FILE_NAME = "On-street_Parking_Bay_Sensors.csv"
FILE_ROWS_COUNT = 3123

def test_pipeline_succeeded(adf_pipeline_run, blob_service_client):
    """Test that pipeline has copied target CSV file to container of sink storage account"""
    this_run = adf_pipeline_run(PIPELINE_NAME, run_inputs={"fileName": FILE_NAME})
    
    # Assert pipeline execution status
    assert this_run.status == "Succeeded"

    # Assert sinked file in target storage account
    blob_container_client = blob_service_client.get_container_client(SINK_CONTAINER)
    blobs_list = list(blob_container_client.list_blobs(FILE_PATH, None))
    assert len(blobs_list) == 1
    
    blob = blobs_list[0]
    assert blob.name == FILE_PATH + FILE_NAME
    
    # Assert file row count
    storage_stream_downloader = blob_container_client.download_blob(blob.name, None, None)
    blob_bytes = storage_stream_downloader.readall()
    
    contents_array = blob_bytes.decode("UTF-8").split("\n")
    assert len(contents_array) == FILE_ROWS_COUNT
