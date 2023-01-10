"""
Load environment configurations to Settings class.
"""
from functools import lru_cache
from typing import Optional

from pydantic import BaseSettings


class Settings(BaseSettings):
    """
    Settings class for configurations.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    RUN_ENVIRONMENT: str = None
    AZ_KEYVAULT_NAME: str = None
    AZ_BATCH_KEY_NAME: str = None
    AZ_BATCH_ACCOUNT_URL: str = None
    AZ_BATCH_ACCOUNT_NAME: str = None
    AZ_BATCH_EXECUTION_POOL_ID: str = None
    AZ_BATCH_ORCHESTRATOR_POOL_ID: str = None
    AZ_BATCH_KEY: str = None
    RAW_ZONE_CONTAINER: str = None 
    TASK_RETRY_COUNT: int

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