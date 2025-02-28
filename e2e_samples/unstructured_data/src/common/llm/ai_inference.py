from typing import Any, Optional

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import ImageContentItem, ImageUrl, SystemMessage, TextContentItem, UserMessage
from azure.core.credentials import AzureKeyCredential
from common.config import AzureOpenAIConfig
from common.llm.credentials import OAICredentials
from common.llm.llm_base import LLMBase


class AIInferenceLLM(LLMBase[ChatCompletionsClient]):

    def __init__(self, creds: OAICredentials) -> None:
        self.client = ChatCompletionsClient(
            endpoint=creds.deployment_endpoint,
            credential=AzureKeyCredential(creds.api_key),
            # api_key=creds.api_key,
            api_version=creds.api_version,
        )

    def user_message(self, content: str | list) -> UserMessage:
        return UserMessage(content=content)

    def system_message(self, content: str) -> SystemMessage:
        return SystemMessage(content=content)

    def image_content_item(
        self, image_file: str, image_format: str = "png", detail: Optional[Any] = None
    ) -> ImageContentItem:
        return ImageContentItem(
            image_url=ImageUrl.load(image_file=image_file, image_format=image_format, detail=detail)
        )

    def text_content_item(self, text: str) -> TextContentItem:
        return TextContentItem(text=text)

    def json_response_format(self) -> str:
        return "json_object"


def get_chat_completions_client(config: Optional[AzureOpenAIConfig]) -> ChatCompletionsClient:
    if config is None:
        config = AzureOpenAIConfig()
    return ChatCompletionsClient(
        endpoint=config.deployment_endpoint,
        credential=AzureKeyCredential(config.api_key),
        api_version=config.api_version,
    )
