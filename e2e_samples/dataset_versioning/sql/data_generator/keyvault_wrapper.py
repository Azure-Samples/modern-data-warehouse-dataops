from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential
import urllib.parse


class KeyvaultWrapper:
    def __init__(self, uri):
        credential = DefaultAzureCredential(
            exclude_shared_token_cache_credential=True,
            exclude_managed_identity_credential=True,
            exclude_visual_studio_code_credential=True,
            exclude_environment_credential=True
        )
        client = SecretClient(vault_url=uri, credential=credential)
        self.password = urllib.parse.quote_plus(client.get_secret("sql-password").value)
        self.user_name = urllib.parse.quote_plus(client.get_secret("sql-userid").value)
        self.server = urllib.parse.quote_plus(client.get_secret("sqlserver").value)
        self.database = urllib.parse.quote_plus(client.get_secret("sql-db").value)
        self.table_name = urllib.parse.quote_plus(client.get_secret("sql-table").value)
