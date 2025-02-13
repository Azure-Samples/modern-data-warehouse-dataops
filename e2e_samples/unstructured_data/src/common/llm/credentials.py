import os
from dataclasses import dataclass


@dataclass
class OAICredentials:
    endpoint: str
    api_key: str
    api_version: str
    deployment_endpoint: str
    deployment_name: str

    @classmethod
    def from_env(cls) -> "OAICredentials":
        endpoint = os.environ["AZURE_OPENAI_ENDPOINT"]
        deployment_name = os.environ["AZURE_OPENAI_MODEL_DEPLOYMENT_NAME"]
        api_version = os.environ["AZURE_OPENAI_VERSION"]
        api_key = os.environ["AZURE_OPENAI_API_KEY"]
        deployment_endpoint = endpoint + "/openai/deployments/" + deployment_name
        return cls(
            endpoint=endpoint,
            api_key=api_key,
            api_version=api_version,
            deployment_endpoint=deployment_endpoint,
            deployment_name=deployment_name,
        )
