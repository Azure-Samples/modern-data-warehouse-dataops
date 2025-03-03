from dataclasses import dataclass
from typing import Optional

from azure.ai.inference import ChatCompletionsClient
from azure.core.credentials import AzureKeyCredential
from common.env import (
    AZURE_OPENAI_API_KEY,
    AZURE_OPENAI_API_VERSION,
    AZURE_OPENAI_ENDPOINT,
    AZURE_OPENAI_MODEL_DEPLOYMENT_NAME,
)


@dataclass
class AzureOpenAIConfig:
    api_key: str
    api_version: str
    deployment_name: str
    endpoint: str
    deployment_endpoint: str

    @classmethod
    def from_env(cls) -> "AzureOpenAIConfig":
        endpoint = AZURE_OPENAI_ENDPOINT.get_strict()
        deployment_name = AZURE_OPENAI_MODEL_DEPLOYMENT_NAME.get_strict()
        return cls(
            api_key=AZURE_OPENAI_API_KEY.get_strict(),
            api_version=AZURE_OPENAI_API_VERSION.get_strict(),
            deployment_name=deployment_name,
            endpoint=endpoint,
            deployment_endpoint=f"{endpoint}/openai/deployments/{deployment_name}",
        )


def get_chat_completions_client(config: Optional[AzureOpenAIConfig]) -> ChatCompletionsClient:
    if config is None:
        config = AzureOpenAIConfig.from_env()
    return ChatCompletionsClient(
        endpoint=config.deployment_endpoint,
        credential=AzureKeyCredential(config.api_key),
        api_version=config.api_version,
    )
