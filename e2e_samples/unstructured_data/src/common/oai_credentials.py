from dataclasses import dataclass

from common.config import Config


@dataclass
class OAICredentials:
    endpoint: str
    api_key: str
    api_version: str
    deployment_endpoint: str
    deployment_name: str

    @classmethod
    def from_config(cls, config: Config) -> "OAICredentials":
        if config.azure_openai_endpoint is None:
            raise ValueError("AZURE_OPENAI_ENDPOINT is not set")
        if config.azure_openai_api_key is None:
            raise ValueError("AZURE_OPENAI_API_KEY is not set")
        if config.azure_openai_api_version is None:
            raise ValueError("AZURE_OPENAI_API_VERSION is not set")
        if config.azure_openai_deployment_name is None:
            raise ValueError("AZURE_OPENAI_MODEL_DEPLOYMENT_NAME is not set")

        deployment_endpoint = f"{config.azure_openai_endpoint}/openai/deployments/{config.azure_openai_deployment_name}"
        return cls(
            endpoint=config.azure_openai_endpoint,
            api_key=config.azure_openai_api_key,
            api_version=config.azure_openai_api_version,
            deployment_endpoint=deployment_endpoint,
            deployment_name=config.azure_openai_deployment_name,
        )
