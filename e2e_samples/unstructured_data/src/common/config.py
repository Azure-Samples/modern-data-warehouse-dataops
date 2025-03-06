from dataclasses import dataclass
from typing import Optional

from common.azure_storage_utils import AzureStorageConfig
from common.citation_db import CitationDBConfig
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
    def fetch(
        cls, fetcher: Fetcher, db_creator: Optional[str], db_enabled: bool = False, db_form_suffix: Optional[str] = None
    ) -> "CitationGeneratorConfig":
        """
        Fetches the configuration settings from the environment variables.
        """
        storage = AzureStorageConfig.fetch(fetcher)
        di = DIConfig.fetch(fetcher)
        azure_openai = AzureOpenAIConfig.fetch(fetcher)
        db = None
        if db_enabled:
            if db_creator is None:
                raise ValueError("db_creator must be provided if CITATION_DB_ENABLED")
            db = CitationDBConfig.fetch(fetcher, db_creator, db_form_suffix)

        return cls(az_storage=storage, di=di, azure_openai=azure_openai, db=db)
