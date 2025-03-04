from dataclasses import dataclass
from pathlib import Path

from azure.ai.formrecognizer import AnalyzeResult, DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from common.config_utils import Fetcher


@dataclass
class DIConfig:
    endpoint: str
    api_key: str

    @classmethod
    def fetch(cls, fetcher: Fetcher) -> "DIConfig":
        return cls(
            endpoint=fetcher.get_strict("DOCUMENT_INTELLIGENCE_ENDPOINT"),
            api_key=fetcher.get_strict("DOCUMENT_INTELLIGENCE_KEY"),
        )


def get_doc_analysis_client(config: DIConfig) -> DocumentAnalysisClient:
    return DocumentAnalysisClient(endpoint=config.endpoint, credential=AzureKeyCredential(config.api_key))


def analyze_document(
    file_path: str | Path,
    document_analysis_client: DocumentAnalysisClient,
    model_id: str = "prebuilt-layout",
) -> AnalyzeResult:

    with open(file_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(model_id, f)
    return poller.result()
