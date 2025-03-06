from dataclasses import dataclass

from azure.ai.inference import ChatCompletionsClient
from azure.core.credentials import AzureKeyCredential
from common.config_utils import Fetcher


@dataclass
class AzureOpenAIConfig:
    api_key: str
    api_version: str
    deployment_endpoint: str

    @classmethod
    def fetch(cls, fetcher: Fetcher) -> "AzureOpenAIConfig":
        endpoint = fetcher.get_strict("AZURE_OPENAI_ENDPOINT")
        deployment_name = fetcher.get_strict("AZURE_OPENAI_MODEL_DEPLOYMENT_NAME")
        return cls(
            api_key=fetcher.get_strict("AZURE_OPENAI_API_KEY"),
            api_version=fetcher.get_strict("AZURE_OPENAI_VERSION"),
            deployment_endpoint=f"{endpoint}/openai/deployments/{deployment_name}",
        )


def get_chat_completions_client(config: AzureOpenAIConfig) -> ChatCompletionsClient:
    return ChatCompletionsClient(
        endpoint=config.deployment_endpoint,
        credential=AzureKeyCredential(config.api_key),
        api_version=config.api_version,
    )
