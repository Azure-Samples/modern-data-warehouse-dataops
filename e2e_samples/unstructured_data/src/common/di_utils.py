import os
from pathlib import Path

from azure.ai.formrecognizer import AnalyzeResult, DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential


def get_doc_analysis_client() -> DocumentAnalysisClient:
    endpoint = os.getenv("DOCUMENT_INTELLIGENCE_ENDPOINT")
    api_key = os.getenv("DOCUMENT_INTELLIGENCE_KEY")

    if endpoint is None or api_key is None:
        raise ValueError("DOCUMENT_INTELLIGENCE_ENDPOINT and DOCUMENT_INTELLIGENCE_KEY must be set")

    return DocumentAnalysisClient(endpoint=endpoint, credential=AzureKeyCredential(api_key))


def analyze_document(
    file_path: str | Path,
    document_analysis_client: DocumentAnalysisClient,
    model_id: str = "prebuilt-layout",
) -> AnalyzeResult:

    with open(file_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(model_id, f)
    return poller.result()
