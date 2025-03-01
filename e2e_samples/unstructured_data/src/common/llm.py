from typing import Optional

from azure.ai.inference import ChatCompletionsClient
from azure.core.credentials import AzureKeyCredential
from common.config import AzureOpenAIConfig


def get_chat_completions_client(config: Optional[AzureOpenAIConfig]) -> ChatCompletionsClient:
    if config is None:
        config = AzureOpenAIConfig()
    return ChatCompletionsClient(
        endpoint=config.deployment_endpoint,
        credential=AzureKeyCredential(config.api_key),
        api_version=config.api_version,
    )
