from abc import ABC, abstractmethod
from typing import Any, Generic, TypeVar

T = TypeVar("T")


class LLMBase(Generic[T], ABC):
    client: T

    @abstractmethod
    def user_message(self, content: str) -> Any:
        pass

    @abstractmethod
    def system_message(self, content: str) -> Any:
        pass

    @abstractmethod
    def image_content_item(self, image_file: str, image_format: str = "png") -> Any:
        pass

    @abstractmethod
    def text_content_item(self, text: str) -> Any:
        pass

    @abstractmethod
    def json_response_format(self) -> Any:
        pass
