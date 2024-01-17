from azure.identity import DefaultAzureCredential
from azure.mgmt.datashare import DataShareManagementClient
from azure.mgmt.datashare.models import (
    ADLSGen2FileSystemDataSetMapping,
    ShareSubscription,
)
import logging
from .configuration import Configuration


class DataShareHelper:
    """
    Class with helper functions for DataShare
    """

    _client: DataShareManagementClient
    _config: Configuration

    def __init__(self, config: Configuration) -> None:
        self._config = config
        credentials = DefaultAzureCredential()
        self._client = DataShareManagementClient(
            credential=credentials,
            subscription_id=config.data_share_azure_subscription_id,
        )

    def accept_invitation(self):
        # accept invitation in the context of the current AZ CLI user
        invitations = self.get_consumer_invitations()

        if invitations is None or len(invitations) == 0:
            logging.info("No invitations found for this identity")
        else:
            for invitation in invitations:
                invitation_id = invitation["invitation_id"]
                # set a subscription name - we will use the name of the original share
                subscription_name = f"Subscription_{invitation['share_name']}"
                logging.info(f"Processing invitation {invitation_id}")

                self.create_share_subscription(invitation_id, subscription_name)

                # create mapping
                datasets = self.get_consumer_source_datasets(subscription_name)
                for dataset in datasets:
                    dataset_id = dataset["data_set_id"]
                    dataset_name = dataset["data_set_path"]
                    logging.info(f"Mapping dataset {dataset_name} ({dataset_id})")
                    self.create_dataset_mapping(
                        subscription_name, dataset_id, dataset_name
                    )

                # create trigger
                sync_setting = self.get_subscription_synchronization_setting(
                    subscription_name
                )
                self.create_trigger(subscription_name, sync_setting)

    def get_consumer_invitations(self):
        # get consumer invitations
        logging.info("\n### Get Consumer Invitations ###")
        result = self._client.consumer_invitations.list_invitations()
        invitations = list()
        for x in result:
            logging.info(x.as_dict())
            invitations.append(x.as_dict())
        return invitations

    def create_share_subscription(self, invitation_id, subscription_name):
        # create share subscription
        logging.info(
            f"\n### Create Share Subscription for invitation {invitation_id} ###"
        )
        subscription = ShareSubscription(
            invitation_id=invitation_id, source_share_location="westeurope"
        )
        result = self._client.share_subscriptions.create(
            self._config.data_share_resource_group_name,
            self._config.data_share_account_name,
            subscription_name,
            subscription,
        )
        logging.info(result.as_dict())
        return result

    def get_consumer_source_datasets(self, subscription_name):
        # get source datasets
        logging.info("\n### Get Consumer Source Datasets ###")
        result = self._client.consumer_source_data_sets.list_by_share_subscription(
            self._config.data_share_resource_group_name,
            self._config.data_share_account_name,
            subscription_name,
        )
        data_sets = list()
        for x in result:
            logging.info(x.as_dict())
            data_sets.append(x.as_dict())
        return data_sets

    def create_dataset_mapping(self, subscription_name, dataset_id, dataset_path):
        # create dataset mapping
        logging.info("\n### Create Dataset mappings ###")
        data_set_mapping = ADLSGen2FileSystemDataSetMapping(
            data_set_id=dataset_id,
            file_system=dataset_path,
            subscription_id=self._config.destination_storage_subscription_id,
            resource_group=self._config.destination_storage_resource_group_name,
            storage_account_name=self._config.destination_storage_account_name,
        )
        result = self._client.data_set_mappings.create(
            self._config.data_share_resource_group_name,
            self._config.data_share_account_name,
            subscription_name,
            f"{dataset_path}-dataset-mapping",
            data_set_mapping,
        )
        logging.info(result.as_dict())

    def get_subscription_synchronization_setting(self, subscription_name):
        # get synchronization settings
        logging.info("\n### Get Synchronization Setting ###")
        result = (
            self._client.share_subscriptions.list_source_share_synchronization_settings(
                self._config.data_share_resource_group_name,
                self._config.data_share_account_name,
                subscription_name,
            )
        )

        for x in result:
            # just get the first
            logging.info(x.as_dict())
            return x

    def create_trigger(self, subscription_name, trigger):
        # create trigger
        logging.info("\n### Create Trigger ###")
        result = self._client.triggers.begin_create(
            self._config.data_share_resource_group_name,
            self._config.data_share_account_name,
            subscription_name,
            f"{subscription_name}-trigger",
            trigger,
        )
        logging.info(result.result().as_dict())
