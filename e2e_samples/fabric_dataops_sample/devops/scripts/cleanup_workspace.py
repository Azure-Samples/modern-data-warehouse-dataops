import os

import utils
from dotenv import load_dotenv

load_dotenv()

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Access Token
azure_management_bearer_token = os.environ.get("AZURE_MANAGEMENT_BEARER_TOKEN")
azure_storage_bearer_token = os.environ.get("AZURE_STORAGE_BEARER_TOKEN")
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")

# Azure Resources
subscription_id = os.environ.get("SUBSCRIPTION_ID")
resource_group_name = os.environ.get("RESOURCE_GROUP_NAME")
storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
storage_container_name = os.environ.get("STORAGE_CONTAINER_NAME")

# Fabric
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_connection_name = os.environ.get("FABRIC_CONNECTION_NAME")

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
azure_management_headers = {
    "Authorization": f"Bearer {azure_management_bearer_token}",
    "Content-Type": "application/json",
}
azure_storage_headers = {"Authorization": f"Bearer {azure_storage_bearer_token}", "x-ms-version": "2021-02-12"}
fabric_headers = {"Authorization": f"Bearer {fabric_bearer_token}", "Content-Type": "application/json"}


# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
class ValidationError(Exception):
    def __init__(self, message: str) -> None:
        self.message = message
        print(f"[Error] {self.message}")
        exit(1)


def validate_env() -> None:
    error_list = []

    # Access Token
    if not azure_management_bearer_token:
        error_list.append("AZURE_MANAGEMENT_BEARER_TOKEN")
    if not azure_storage_bearer_token:
        error_list.append("AZURE_STORAGE_BEARER_TOKEN")
    if not fabric_bearer_token:
        error_list.append("FABRIC_BEARER_TOKEN")

    # Azure Resources
    if not subscription_id:
        error_list.append("SUBSCRIPTION_ID")
    if not resource_group_name:
        error_list.append("RESOURCE_GROUP_NAME")
    if not storage_account_name:
        error_list.append("STORAGE_ACCOUNT_NAME")
    if not storage_container_name:
        error_list.append("STORAGE_CONTAINER_NAME")

    # Fabric
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_connection_name:
        error_list.append("FABRIC_CONNECTION_NAME")

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    workspace_id = utils.get_workspace_id(fabric_headers, fabric_workspace_name)
    if not workspace_id:
        print("[Info] ############ No workspace found ############")
        exit(0)

    workspace = utils.get_workspace(fabric_headers, workspace_id)
    if not workspace:
        print("[Info] ############ No workspace found ############")
        exit(0)

    print("[Info] ############ Deleting ADLS Storage Container ############")
    scope = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/"
        f"providers/Microsoft.Storage/storageAccounts/{storage_account_name}"
    )
    workspace_identity = workspace["workspaceIdentity"]
    role_assignment_ids = utils.get_storage_role_assignments(
        azure_management_headers, scope, workspace_identity["servicePrincipalId"]
    )
    for role_assignment_id in role_assignment_ids:
        print(f"[Info] Deleting ADLS storage role assignment: {role_assignment_id}")
        utils.delete_storage_account_role_assignment(azure_management_headers, role_assignment_id)
    print(f"[Info] Deleting ADLS storage container: {storage_account_name} - {storage_container_name}")
    utils.delete_storage_container(azure_storage_headers, storage_account_name, storage_container_name)

    print("[Info] ############ Deleting ADLS Cloud Connection ############")
    connection_id = utils.get_connection_id(fabric_headers, fabric_connection_name)
    if connection_id:
        print(f"[Info] Deleting ADLS cloud connection: {connection_id}")
        utils.delete_adls_cloud_connection(fabric_headers, connection_id)

    print("[Info] ############ Deleting Workspace ############")
    print(f"[Info] Deleting workspace: {workspace_id} - {workspace['displayName']}")
    utils.delete_workspace(fabric_headers, workspace_id)
