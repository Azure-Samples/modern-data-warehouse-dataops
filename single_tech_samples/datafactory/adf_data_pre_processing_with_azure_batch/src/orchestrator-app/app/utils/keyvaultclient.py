from functools import lru_cache
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from core.config import getSettings


settings = getSettings()
keyVaultUrl=f'https://{settings.AZ_KEYVAULT_NAME}.vault.azure.net'
credentials = DefaultAzureCredential()

def getSecretValue(secretName:str):
    """This method provides the latest value for the given secret.
    """
    secretClient = getSecretClient()
    secret = secretClient.get_secret(
        secretName
    )
    return secret.value

@lru_cache()
def getSecretClient():
    """Creates keyvault secret client

    Returns:
        _type_: Returns SecretClient object.
    """
    return SecretClient(vault_url=keyVaultUrl,credential=credentials)
