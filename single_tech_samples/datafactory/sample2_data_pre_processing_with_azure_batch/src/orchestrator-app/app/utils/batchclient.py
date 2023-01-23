"""
Azure batch client helper.
"""
import logging

from functools import lru_cache
from azure.batch import BatchServiceClient
from azure.batch.batch_auth import SharedKeyCredentials
from core.config import getSettings
from utils.confighelper import ConfigHelper

settings=getSettings()
log = logging.getLogger(__name__)
configHelper = ConfigHelper()

@lru_cache()
def getBatchClient():
    """
    This method creates batch account in local and cloud environments.
    """
    credentials = SharedKeyCredentials(settings.AZ_BATCH_ACCOUNT_NAME,
        configHelper.getConfigKeyValue(settings.AZ_BATCH_KEY))
    
    return BatchServiceClient(
        credentials,
        batch_url=settings.AZ_BATCH_ACCOUNT_URL)