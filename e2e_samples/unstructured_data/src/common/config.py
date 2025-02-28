from dataclasses import dataclass
from typing import Optional

from common import env


@dataclass
class AzureOpenAIConfig:
    api_key: str
    api_version: str
    deployment_name: str
    endpoint: str
    deployment_endpoint: str

    def __init__(
        self,
        api_key: Optional[str] = None,
        api_version: Optional[str] = None,
        deployment_name: Optional[str] = None,
        endpoint: Optional[str] = None,
    ):
        self.api_key = api_key or env.AZURE_OPENAI_API_KEY.get_strict()
        self.api_version = api_version or env.AZURE_OPENAI_API_VERSION.get_strict()
        self.deployment_name = deployment_name or env.AZURE_OPENAI_MODEL_DEPLOYMENT_NAME.get_strict()
        self.endpoint = endpoint or env.AZURE_OPENAI_ENDPOINT.get_strict()
        self.deployment_endpoint = f"{self.endpoint}/openai/deployments/{self.deployment_name}"


@dataclass
class DIConfig:
    endpoint: str
    api_key: str
    override_results: bool = False

    def __init__(
        self, endpoint: Optional[str] = None, api_key: Optional[str] = None, override_results: Optional[bool] = False
    ):
        self.endpoint = endpoint or env.DI_ENDPOINT.get_strict()
        self.api_key = api_key or env.DI_KEY.get_strict()

        if override_results is None:
            self.override_results = env.DI_OVERRIDE_RESULTS or False


@dataclass
class AzureStorageConfig:
    account_url: str

    def __init__(self, account_url: Optional[str] = None):
        self.account_url = account_url or env.AZURE_STORAGE_ACCOUNT_URL.get_strict()


@dataclass
class DBConfig:
    connection_string: str
    creator: str


@dataclass
class CitationDBConfig:
    question_id: int
    form_suffix: str
    conn_str: str
    creator: str

    def __init__(self, conn_str: str, question_id: int, creator: str, run_id: Optional[str] = None):
        self.conn_str = conn_str
        self.question_id = question_id
        self.form_suffix = f"_{run_id}" if run_id else ""
        self.creator = creator


def get_citation_db_config(
    creator: str,
    conn_str: Optional[str] = None,
    question_id: Optional[int] = None,
    run_id: Optional[str] = None,
) -> Optional[CitationDBConfig]:

    enabled = env.CITATION_DB_ENABLED or False
    if not enabled:
        return None

    if question_id is None:
        raise KeyError("'question_id' is a required argument when Citation DB is enabled.")

    if conn_str is None:
        conn_str = conn_str or env.CITATION_DB_CONNECTION_STRING.get_strict()

    return CitationDBConfig(conn_str=conn_str, question_id=question_id, creator=creator, run_id=run_id)
