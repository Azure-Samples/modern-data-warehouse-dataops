from core.config import Settings, getSettings
from utils.keyvaultclient import getSecretValue
from azure.identity import DefaultAzureCredential
from utils.enums import RunEnvironment

class ConfigHelper:
    settings: Settings = getSettings()
    
    def getConfigKeyValue(self, key: str) -> str:
        if self.settings.RUN_ENVIRONMENT==RunEnvironment.LOCAL.value:
            return key        
        elif self.settings.RUN_ENVIRONMENT==RunEnvironment.CLOUD.value:
            return getSecretValue(key)
        else:
            raise RuntimeError(f'Error: {self.settings.RUN_ENVIRONMENT} not supported as valid run environment.')
    
    def getStorageAccountCredentials(self, key: str):
        if self.settings.RUN_ENVIRONMENT==RunEnvironment.LOCAL.value:
            return key    
        elif self.settings.RUN_ENVIRONMENT==RunEnvironment.CLOUD.value:
            return DefaultAzureCredential()
        else:
            raise RuntimeError(f'Error: {self.settings.RUN_ENVIRONMENT} not supported as valid run environment.')