from pathlib import Path
from typing import Optional

from azure.ai.formrecognizer import AnalyzeResult, DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from common.config import DIConfig


def get_doc_analysis_client(config: Optional[DIConfig]) -> DocumentAnalysisClient:
    if config is None:
        config = DIConfig()
    return DocumentAnalysisClient(endpoint=config.endpoint, credential=AzureKeyCredential(config.api_key))


def analyze_document(
    file_path: str | Path,
    document_analysis_client: DocumentAnalysisClient,
    model_id: str = "prebuilt-layout",
) -> AnalyzeResult:

    with open(file_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(model_id, f)
    return poller.result()
