import json
import os
import tempfile
from dataclasses import dataclass
from typing import Any

from azure.storage.blob import BlobServiceClient
from common.di_utils import analyze_document, get_doc_analysis_client
from dotenv import load_dotenv


@dataclass
class AnalyzedDocument:
    doc_url: str
    di_url: str
    document_name: str
    di_result: dict


def convert_polygon_format(data: dict | list) -> dict | list | Any:
    if isinstance(data, dict):
        for key, value in data.items():
            if key == "polygon" and isinstance(value, list):
                new_value = []
                for point in value:
                    if isinstance(point, dict) and "x" in point and "y" in point:
                        new_value.extend([point["x"], point["y"]])
                data[key] = new_value
            else:
                convert_polygon_format(value)
    elif isinstance(data, list):
        for item in data:
            convert_polygon_format(item)
    return data


def analyze_submission_folder(
    blob_service_client: BlobServiceClient,
    folder_name: str,
    submission_container: str = "input-documents",
    results_container: str = "di-results",
) -> list[AnalyzedDocument]:
    load_dotenv(override=True)
    override_di = os.getenv("OVERRIDE_DI_RESULTS", False)

    # model_id and di_client can be configurable in the future
    model_id = "prebuilt-layout"
    di_client = get_doc_analysis_client()

    submission_container_client = blob_service_client.get_container_client(submission_container)
    results_container_client = blob_service_client.get_container_client(results_container)

    docs = []
    blob_list = submission_container_client.list_blobs(name_starts_with=folder_name + "/")
    # we currently only want to process pdfs
    # blob_list = [doc for doc in blob_list if doc.name.endswith(".pdf")]

    for submission in blob_list:
        doc_name = f"formRecognizer/{model_id}/{submission.name}"
        submission_blob_client = submission_container_client.get_blob_client(submission.name)
        results_blob_client = results_container_client.get_blob_client(doc_name + ".json")

        # If DI results already exist and we're not overriding, load it into memory
        if results_blob_client.exists() and not override_di:
            blob_data = results_blob_client.download_blob()
            content = blob_data.readall()
            content = json.loads(content)
        else:
            # Downloading document locally
            blob_data = submission_blob_client.download_blob()
            content = blob_data.readall()

            # Creating tempfile to load document into DI
            with tempfile.NamedTemporaryFile(delete=False) as temp:
                temp.write(content)

            # Getting Document Intelligence results for the document
            di_result = analyze_document(temp.name, di_client)
            content = di_result.to_dict()

            # Fix SDK Polygon formatting
            fixed_content = convert_polygon_format(content)

            # Upload results to blob di-results container
            results_blob_client.upload_blob(json.dumps(fixed_content), overwrite=True)
            os.remove(temp.name)

        doc_url = submission_blob_client.url
        di_url = results_blob_client.url
        docs.append(AnalyzedDocument(doc_url, di_url, submission.name.split("/")[-1], content))
    return docs
