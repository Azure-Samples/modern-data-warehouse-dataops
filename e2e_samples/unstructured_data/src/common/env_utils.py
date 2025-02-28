import os
from dataclasses import dataclass
from typing import Generic, Optional, TypeVar, Union

T = TypeVar("T", str, None, bool)


@dataclass
class EnvVar(Generic[T]):
    key: str
    value: Union[Optional[str], T]

    def __init__(self, key: str, default: Optional[T] = None) -> None:
        self.key = key
        self.value = self._get_value(key, default)

    def _get_value(self, key: str, default: Optional[T]) -> Union[Optional[str], T]:
        return os.getenv(key, default)

    def get_strict(self) -> Union[str, T]:
        if self.value is None:
            raise KeyError(f"{self.key} is required.")
        else:
            return self.value


@dataclass
class EnvVarBool(EnvVar[bool]):
    value: Optional[bool]

    def _get_value(self, key: str, default: Optional[bool] = None) -> Optional[bool]:
        value = os.getenv(key, default)
        if isinstance(value, str):
            return value.lower() == "true"
        return default

    def __init__(self, key: str, default: Optional[bool] = None) -> None:
        self.key = key
        self.value = self._get_value(key, default)
