from pathlib import Path

from azure.ai.formrecognizer import AnalyzeResult, DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential


def get_doc_analysis_client(endpoint: str, api_key: str) -> DocumentAnalysisClient:

    return DocumentAnalysisClient(endpoint=endpoint, credential=AzureKeyCredential(api_key))


def analyze_document(
    file_path: str | Path,
    document_analysis_client: DocumentAnalysisClient,
    model_id: str = "prebuilt-layout",
) -> AnalyzeResult:

    with open(file_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(model_id, f)
    return poller.result()
