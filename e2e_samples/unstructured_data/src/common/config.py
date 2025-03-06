from dataclasses import dataclass
from typing import Optional

from common.azure_storage_utils import AzureStorageConfig
from common.citation_db import CitationDBConfig, CitationDBOptions
from common.config_utils import Fetcher
from common.di_utils import DIConfig
from common.llm import AzureOpenAIConfig


@dataclass
class CitationGeneratorConfig:
    """
    Configuration class for CitationDB.
    This class is used to store the configuration settings for the CitationDB.
    """

    az_storage: AzureStorageConfig
    di: DIConfig
    azure_openai: AzureOpenAIConfig
    db: Optional[CitationDBConfig] = None

    @classmethod
    def fetch(cls, fetcher: Fetcher, db_options: Optional[CitationDBOptions] = None) -> "CitationGeneratorConfig":
        """
        Fetches the configuration settings from the environment variables.
        """
        storage = AzureStorageConfig.fetch(fetcher)
        di = DIConfig.fetch(fetcher)
        azure_openai = AzureOpenAIConfig.fetch(fetcher)
        db = CitationDBConfig.fetch(fetcher, db_options) if db_options is not None else None

        return cls(az_storage=storage, di=di, azure_openai=azure_openai, db=db)
