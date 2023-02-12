"""
Load environment configurations to Settings class.
"""
import os
from functools import lru_cache
from typing import Optional

from pydantic import BaseSettings


class Settings(BaseSettings):
    """
    Settings class for configurations.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    RUN_ENVIRONMENT: str = os.getenv("RUN_ENVIRONMENT",default="CLOUD")
    AZ_KEYVAULT_NAME: str = None
    AZ_ACR_NAME: str = None
    AZ_BATCH_ACCOUNT_URL: str = os.getenv("AZ_BATCH_ACCOUNT_URL",default=None)
    AZ_BATCH_ACCOUNT_NAME: str = os.getenv("AZ_BATCH_ACCOUNT_NAME",default=None)
    AZ_BATCH_EXECUTION_POOL_ID: str = os.getenv("AZ_BATCH_EXECUTION_POOL_ID",default="executionpool")
    AZ_BATCH_KEY: str = "azurebatchkey"

    class Config:
        """
        Environment file name
        """

        env_file = ".env"


@lru_cache()
def getSettings():
    """Get settings object.

    Returns:
        _type_: Returns Settings object
    """
    return Settings()
