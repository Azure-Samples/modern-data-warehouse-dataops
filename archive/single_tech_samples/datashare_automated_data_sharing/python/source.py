from datetime import datetime
from pprint import pprint
import os, sys

from azure.identity import DefaultAzureCredential, AzureCliCredential
from azure.core.exceptions import ResourceNotFoundError
from azure.mgmt.datashare import DataShareManagementClient
from azure.mgmt.datashare.models import (
    ADLSGen2FileSystemDataSet,
    Invitation,
    ScheduledSynchronizationSetting,
    Share,
    ShareKind,
)
from dotenv import load_dotenv

# load configuration
path = "source.env"

if not os.path.exists(path):
    print(f"Could not load '{path}' config file...")
    sys.exit()
else:
    load_dotenv(path, verbose=True)
    print(f"Loaded '{path}' config file!")

# source data share settings
data_share_azure_subscription_id: str = os.getenv("DATA_SHARE_AZURE_SUBSCRIPTION_ID")
data_share_resource_group_name: str = os.getenv("DATA_SHARE_RESOURCE_GROUP")
data_share_account_name: str = os.getenv("DATA_SHARE_ACCOUNT_NAME")
share_name: str = os.getenv("SHARE_NAME")
dataset_name: str = os.getenv("DATASET_NAME")

# source storage account settings
storage_account_azure_subscription_id: str = os.getenv("STORAGE_AZURE_SUBSCRIPTION_ID")
storage_account_resource_group_name: str = os.getenv("STORAGE_RESOURCE_GROUP")
storage_account_name: str = os.getenv("STORAGE_ACCOUNT_NAME")
file_system_name: str = os.getenv("FILE_SYSTEM_NAME")

# destination object for invitation
dest_tenant_id: str = os.getenv("DESTINATION_TENANT_ID")
dest_object_id: str = os.getenv("DESTINATION_OBJECT_ID")


def create_share_in_account(client: DataShareManagementClient):
    # create share in account
    print("\n### Create Share in Account ###")
    share = Share(
        description="some description",
        share_kind=ShareKind("CopyBased"),
        terms="terms of use",
    )
    result = client.shares.create(
        data_share_resource_group_name, data_share_account_name, share_name, share
    )
    pprint(result.as_dict())


def set_schedule(client: DataShareManagementClient):
    # set share schedule
    print("\n### Set Share Schedule ###")

    # check if exists
    try:
        sync_settings = client.synchronization_settings.get(
            data_share_resource_group_name,
            data_share_account_name,
            share_name,
            f"{share_name}-synchronization-settings",
        )
    except ResourceNotFoundError:
        sync_settings = None

    if sync_settings is None:
        settings = ScheduledSynchronizationSetting(
            recurrence_interval="Day", synchronization_time=datetime.now()
        )

        result = client.synchronization_settings.create(
            data_share_resource_group_name,
            data_share_account_name,
            share_name,
            f"{share_name}-synchronization-settings",
            settings,
        )
        pprint(result.as_dict())
    else:
        print("Schedule already exists")
        pprint(sync_settings.as_dict())


def create_dataset(client: DataShareManagementClient):
    # create dataset
    print("\n### Create Dataset ###")

    data_set = ADLSGen2FileSystemDataSet(
        file_system=file_system_name,
        subscription_id=storage_account_azure_subscription_id,
        resource_group=storage_account_resource_group_name,
        storage_account_name=storage_account_name,
    )

    result = client.data_sets.create(
        data_share_resource_group_name,
        data_share_account_name,
        share_name,
        dataset_name,
        data_set,
    )
    pprint(result.as_dict())


def create_invitation_by_email(
    client: DataShareManagementClient, invitation_name, email
):
    # create invitation
    print("\n### Create Invitation ###")
    invitation = Invitation(target_email=email)
    result = client.invitations.create(
        data_share_resource_group_name,
        data_share_account_name,
        share_name,
        invitation_name,
        invitation,
    )
    print(result.as_dict())


def create_invitation_by_target_id(
    client: DataShareManagementClient, invitation_name, tenant_id, client_id
):
    # create invitation
    print("\n### Create Invitation ###")
    invitation = Invitation(
        target_active_directory_id=tenant_id, target_object_id=client_id
    )
    result = client.invitations.create(
        data_share_resource_group_name,
        data_share_account_name,
        share_name,
        invitation_name,
        invitation,
    )
    print(result.as_dict())


def main():

    # authenticate
    cred = DefaultAzureCredential(exclude_visual_studio_code_credential=True)

    # create client
    client = DataShareManagementClient(cred, data_share_azure_subscription_id)

    # create source share
    create_share_in_account(client)

    # create dataset
    create_dataset(client)

    # create schedule
    set_schedule(client)

    # send invitation to service principal
    create_invitation_by_target_id(
        client=client,
        invitation_name="test-sp",
        tenant_id=dest_tenant_id,
        client_id=dest_object_id,
    )


if __name__ == "__main__":
    main()
