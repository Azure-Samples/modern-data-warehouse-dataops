from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from azure.ai.formrecognizer import AnalyzeResult, DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from common.env import DI_ENDPOINT, DI_KEY, DI_OVERRIDE_RESULTS


@dataclass
class DIConfig:
    endpoint: str
    api_key: str
    override_results: bool = False

    @classmethod
    def from_env(cls) -> "DIConfig":
        return cls(
            endpoint=DI_ENDPOINT.get_strict(),
            api_key=DI_KEY.get_strict(),
            override_results=DI_OVERRIDE_RESULTS or False,
        )


def get_doc_analysis_client(config: Optional[DIConfig]) -> DocumentAnalysisClient:
    if config is None:
        config = DIConfig.from_env()
    return DocumentAnalysisClient(endpoint=config.endpoint, credential=AzureKeyCredential(config.api_key))


def analyze_document(
    file_path: str | Path,
    document_analysis_client: DocumentAnalysisClient,
    model_id: str = "prebuilt-layout",
) -> AnalyzeResult:

    with open(file_path, "rb") as f:
        poller = document_analysis_client.begin_analyze_document(model_id, f)
    return poller.result()
