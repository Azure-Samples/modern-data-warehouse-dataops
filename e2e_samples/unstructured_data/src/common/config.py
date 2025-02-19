from dataclasses import dataclass
from typing import Optional

import common.env as env
from dotenv import load_dotenv

load_dotenv()


@dataclass
class Config:
    azure_openai_api_version: Optional[str] = None
    azure_openai_api_key: Optional[str] = None
    azure_openai_endpoint: Optional[str] = None
    azure_openai_deployment_name: Optional[str] = None
    di_endpoint: Optional[str] = None
    di_key: Optional[str] = None
    azure_storage_account_url: Optional[str] = None
    citation_db_enabled: bool = False
    citation_db_conn_str: Optional[str] = None
    override_di_results: bool = False

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            azure_openai_api_version=env.AZURE_OPENAI_API_VERSION,
            azure_openai_api_key=env.AZURE_OPENAI_API_KEY,
            azure_openai_endpoint=env.AZURE_OPENAI_ENDPOINT,
            azure_openai_deployment_name=env.AZURE_OPENAI_MODEL_DEPLOYMENT_NAME,
            di_endpoint=env.DOCUMENT_INTELLIGENCE_ENDPOINT,
            di_key=env.DOCUMENT_INTELLIGENCE_KEY,
            azure_storage_account_url=env.AZURE_STORAGE_ACCOUNT_URL,
            citation_db_enabled=env.CITATION_DB_ENABLED,
            citation_db_conn_str=env.CITATION_DB_CONNECTION_STRING,
            override_di_results=env.CITATION_DB_ENABLED,
        )
