import base64
from typing import Any

from common.llm.credentials import OAICredentials
from common.llm.llm_base import LLMBase
from openai import AzureOpenAI, NotGiven
from openai.types.chat.chat_completion import ChatCompletion

NOT_GIVEN = NotGiven()


class AzureOpenAIClient(AzureOpenAI):
    def __init__(self, creds: OAICredentials) -> None:
        super().__init__(
            azure_endpoint=creds.endpoint,
            api_key=creds.api_key,
            api_version=creds.api_version,
        )
        self._deployment_name = creds.deployment_name

    def complete(
        self,
        messages: list,
        response_format: Any | NotGiven = NOT_GIVEN,
        **kwargs: Any,
    ) -> ChatCompletion:
        return self.chat.completions.create(
            messages=messages,
            model=self._deployment_name,
            response_format=response_format,
            **kwargs,
        )


class AzureOpenAILLM(LLMBase[AzureOpenAIClient]):

    def __init__(self, creds: OAICredentials) -> None:
        self.client = AzureOpenAIClient(creds)

    def user_message(self, content: str) -> dict:
        return {"role": "user", "content": content}

    def system_message(self, content: str) -> dict:
        return {"role": "system", "content": content}

    def image_content_item(self, image_file: str, image_format: str = "png") -> dict:
        with open(image_file, "rb") as f:
            base64_image = base64.b64encode(f.read()).decode("utf-8")
        return {
            "type": "image_url",
            "image_url": {"url": f"data:image/{image_format};base64,{base64_image}"},
        }

    def text_content_item(self, text: str) -> dict:
        return {"type": "text", "text": text}

    def json_response_format(self) -> dict:
        return {"type": "json_object"}
