import os
import logging


class Configuration(object):
    """
    Configuration class
    """

    _data_share_account_name: str
    _data_share_resource_group_name: str
    _data_share_azure_subscription_id: str
    _destination_storage_account_name: str
    _destination_storage_resource_group_name: str
    _destination_storage_subscription_id: str

    def __init__(self):
        self._data_share_account_name = ""
        self._data_share_resource_group_name = ""
        self._data_share_azure_subscription_id = ""
        self._destination_storage_account_name = ""
        self._destination_storage_resource_group_name = ""
        self._destination_storage_subscription_id = ""

    def _get_value(self, key: str):
        """
        Get a configuration value
        """
        value = os.getenv(key)
        if value is None:
            logging.error(f"No value found for key: {key}")
            raise Exception(f"No value found for key: {key}")

        return str(value)

    @property
    def data_share_account_name(self):
        """
        Data share account name
        """
        if not self._data_share_account_name:
            self._data_share_account_name = self._get_value("DATA_SHARE_ACCOUNT_NAME")
        return self._data_share_account_name

    @property
    def data_share_resource_group_name(self):
        """
        Data share resource group name
        """
        if not self._data_share_resource_group_name:
            self._data_share_resource_group_name = self._get_value(
                "DATA_SHARE_RESOURCE_GROUP_NAME"
            )
        return self._data_share_resource_group_name

    @property
    def data_share_azure_subscription_id(self):
        """
        Data Share subscription id
        """
        if not self._data_share_azure_subscription_id:
            self._data_share_azure_subscription_id = self._get_value(
                "DATA_SHARE_AZURE_SUBSCRIPTION_ID"
            )
        return self._data_share_azure_subscription_id

    @property
    def destination_storage_account_name(self):
        """
        DataShare Destination Storage Account System name
        """
        if not self._destination_storage_account_name:
            self._destination_storage_account_name = self._get_value(
                "DESTINATION_STORAGE_ACCOUNT_NAME"
            )
        return self._destination_storage_account_name

    @property
    def destination_storage_resource_group_name(self):
        """
        DataShare Destination Storage Account System name
        """
        if not self._destination_storage_resource_group_name:
            self._destination_storage_resource_group_name = self._get_value(
                "DESTINATION_STORAGE_RESOURCE_GROUP_NAME"
            )
        return self._destination_storage_resource_group_name

    @property
    def destination_storage_subscription_id(self):
        """
        DataShare Destination Storage Account System name
        """
        if not self._destination_storage_subscription_id:
            self._destination_storage_subscription_id = self._get_value(
                "DESTINATION_STORAGE_SUBSCRIPTION_ID"
            )
        return self._destination_storage_subscription_id
