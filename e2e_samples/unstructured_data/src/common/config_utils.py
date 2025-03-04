import os
from abc import ABC, abstractmethod
from typing import Optional, TypeVar, Union

from dotenv import load_dotenv

load_dotenv()

T = TypeVar("T")


class Fetcher(ABC):
    """
    Abstract class for getting values from different sources.
    """

    @abstractmethod
    def _get(self, key: str) -> Optional[str]:
        """
        Abstract method to get the value.

        :param key: The key to look up.
        :param default: The default value if the key is not found.
        :return: The value associated with the key.
        """
        pass

    def get_strict(self, key: str, default: Optional[T] = None) -> Union[str, T]:
        """
        Retrieve the value strictly, raising an error if not found.

        :param key: The key to look up.
        :param default: The default value if the key is not found.
        :return: The value associated with the key.
        :raises KeyError: If the key is not found and no default is provided.
        """
        value = self.get(key, default)
        if value is None:
            raise KeyError(f"{key} is required.")
        return value

    def get(self, key: str, default: Optional[T] = None) -> Optional[Union[str, T]]:
        value = self._get(key)
        if value is None:
            return default

        return value

    def get_bool(self, key: str, default: Optional[bool] = None) -> bool:
        value = self._get(key)
        if isinstance(value, str):
            return value.lower() == "true"
        return default if default else False


class EnvFetcher(Fetcher):
    """
    Class to get values from environment variables.
    """

    def _get(self, key: str) -> Optional[str]:
        """
        Get the value from the environment variable.

        :param key: The key to look up.
        :param default: The default value if the key is not found.
        :return: The value associated with the key.
        """
        return os.getenv(key)
