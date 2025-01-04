import json
import os
import time
import uuid
from typing import Dict, Optional

import requests
import yaml
from dotenv import load_dotenv
from requests.structures import CaseInsensitiveDict

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
fabric_workspace_group_admin = os.environ.get("FABRIC_WORKSPACE_GROUP_ADMIN")
storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
storage_account_role_definition_id = os.environ.get("STORAGE_ACCOUNT_ROLE_DEFINITION_ID")
storage_container_name = os.environ.get("STORAGE_CONTAINER_NAME")

# Azure Devops
organization_name = os.environ.get("ORGANIZATIONAL_NAME")
project_name = os.environ.get("PROJECT_NAME")
repo_name = os.environ.get("REPO_NAME")
fabric_workspace_directory = os.environ.get("FABRIC_WORKSPACE_DIRECTORY")
feature_branch = os.environ.get("FEATURE_BRANCH")
commit_hash = os.environ.get("COMMIT_HASH")

# Fabric
fabric_capacity_name = os.environ.get("FABRIC_CAPACITY_NAME")
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_environment_name = os.environ.get("FABRIC_ENVIRONMENT_NAME")
fabric_custom_pool_name = os.environ.get("FABRIC_CUSTOM_POOL_NAME")
fabric_connection_name = os.environ.get("FABRIC_CONNECTION_NAME")
fabric_lakehouse_name = os.environ.get("FABRIC_LAKEHOUSE_NAME")
fabric_shortcut_name = os.environ.get("FABRIC_SHORTCUT_NAME")

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
azure_management_headers: Dict[str, str] = {}
azure_storage_headers: Dict[str, str] = {}
fabric_headers: Dict[str, str] = {}

fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"


def set_azure_management_headers(azure_management_bearer_token: str) -> None:
    global azure_management_headers
    azure_management_headers = {
        "Authorization": f"Bearer {azure_management_bearer_token}",
        "Content-Type": "application/json",
    }


def set_azure_storage_headers(azure_storage_bearer_token: str) -> None:
    global azure_storage_headers
    azure_storage_headers = {"Authorization": f"Bearer {azure_storage_bearer_token}", "x-ms-version": "2021-02-12"}


def set_fabric_headers(fabric_bearer_token: str) -> None:
    global fabric_headers
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
    if not fabric_workspace_group_admin:
        error_list.append("FABRIC_WORKSPACE_GROUP_ADMIN")
    if not storage_account_name:
        error_list.append("STORAGE_ACCOUNT_NAME")
    if not storage_account_role_definition_id:
        error_list.append("STORAGE_ACCOUNT_ROLE_DEFINITION_ID")
    if not storage_container_name:
        error_list.append("STORAGE_CONTAINER_NAME")

    # Azure Devops
    if not organization_name:
        error_list.append("ORGANIZATIONAL_NAME")
    if not project_name:
        error_list.append("PROJECT_NAME")
    if not repo_name:
        error_list.append("REPO_NAME")
    if not fabric_workspace_directory:
        error_list.append("FABRIC_WORKSPACE_DIRECTORY")
    if not feature_branch:
        error_list.append("FEATURE_BRANCH")
    if not commit_hash:
        error_list.append("COMMIT_HASH")

    # Fabric
    if not fabric_capacity_name:
        error_list.append("FABRIC_CAPACITY_NAME")
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_environment_name:
        error_list.append("FABRIC_ENVIRONMENT_NAME")
    if not fabric_custom_pool_name:
        error_list.append("FABRIC_CUSTOM_POOL_NAME")
    if not fabric_connection_name:
        error_list.append("FABRIC_CONNECTION_NAME")
    if not fabric_lakehouse_name:
        error_list.append("FABRIC_LAKEHOUSE_NAME")
    if not fabric_shortcut_name:
        error_list.append("FABRIC_SHORTCUT_NAME")

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------


# List workspaces:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/list-workspaces
def get_workspace_id(workspace_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No workspaces found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve workspaces: {response.status_code} - {response.text}")

    workspaces = response.json().get("value", [])

    for workspace in workspaces:
        if workspace.get("displayName") == workspace_name:
            return workspace.get("id")
    return None


# Get Workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/get-workspace
def get_workspace(workspace_id: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] Workspace not found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve workspace: {response.status_code} - {response.text}")

    return response.json()


# List Capacities:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/capacities/list-capacities
def get_capacity_id(capacity_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/capacities"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No capacities found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve capacities: {response.status_code} - {response.text}")

    capacities = response.json().get("value", [])

    for capacity in capacities:
        if capacity.get("displayName") == capacity_name:
            return capacity.get("id")
    return None


# List Environments:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/items/list-environments
def get_environment_id(workspace_id: str, environment_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No environments found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve environments: {response.status_code} - {response.text}")

    environments = response.json().get("value", [])

    for environment in environments:
        if environment.get("displayName") == environment_name:
            return environment.get("id")
    return None


# List Connections:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/list-connections
def get_connection_id(connection_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/connections"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No connections found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve connections: {response.status_code} - {response.text}")

    connections = response.json().get("value", [])

    for connection in connections:
        if connection.get("displayName") == connection_name:
            return connection.get("id")
    return None


# List workspace custom pools:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/list-workspace-custom-pools
def get_custom_pool_id(workspace_id: str, custom_pool_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No custom pools found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve custom pool: {response.status_code} - {response.text}")

    custom_pools = response.json().get("value", [])

    for custom_pool in custom_pools:
        if custom_pool.get("name") == custom_pool_name:
            return custom_pool.get("id")
    return None


# List items:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/items/list-items
def get_item_id(workspace_id: str, type: str, item_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No items found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve items: {response.status_code} - {response.text}")

    items = response.json().get("value", [])

    for item in items:
        if item.get("displayName") == item_name and item.get("type") == type:
            return item.get("id")
    return None


# Get shortcut:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/onelake-shortcuts/get-shortcut
def get_shortcut(workspace_id: str, item_id: str, shortcut_path: str, shortcut_name: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items/{item_id}/shortcuts/{shortcut_path}/{shortcut_name}"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] Shortcut not found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve shortcuts: {response.status_code} - {response.text}")

    return response.json()


# Get operation result:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/long-running-operations/get-operation-result
def get_operation_result(response_headers: CaseInsensitiveDict) -> Optional[dict]:

    operation_id = response_headers.get("x-ms-operation-id")

    url = f"{fabric_api_endpoint}/operations/{operation_id}/result"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] Operation result not found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve operation result: {response.status_code} - {response.text}")

    return response.json()


# Get operation state:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/long-running-operations/get-operation-state
def poll_long_running_operation(response_headers: CaseInsensitiveDict) -> str:
    operation_id = response_headers.get("x-ms-operation-id")
    retry_after = response_headers.get("Retry-After")

    print(f"[Info] Polling long running operation with id '{operation_id}' every '{retry_after}' seconds.")

    url = f"{fabric_api_endpoint}/operations/{operation_id}"

    while True:

        response = requests.get(url, headers=fabric_headers)

        if response.status_code == 200:
            operation_status = response.json().get("status")
            if operation_status == "Succeeded":
                print("[Info] Long running operation completed successfully.")
                return operation_status
            elif operation_status == "Failed":
                print("[Error] Long running operation failed.")
                return operation_status
            else:
                print("[Info] Long running operation in progress.")
                time.sleep(int(retry_after) if retry_after else 0)
        else:
            raise Exception(f"[Error] Failed to retrieve operation status: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Workspace Functions
# -----------------------------------------------------------------------------


# Create workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/create-workspace
def create_workspace(workspace_name: str, capacity_id: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces"

    payload = {
        "displayName": workspace_name,
        "capacityId": capacity_id,
        "description": f"Workspace {workspace_name}",
    }

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Workspace '{workspace_name}' created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(
            f"[Error] Failed to create workspace '{workspace_name}': {response.status_code} - {response.text}"
        )


# Delete workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/delete-workspace
def delete_workspace(workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}"

    response = requests.delete(url, headers=fabric_headers)

    if response.status_code == 200:
        print("[Info] Workspace deleted successfully.")
    else:
        raise Exception(f"[Error] Failed to delete workspace': {response.status_code} - {response.text}")


# Add workspace role assignments:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/add-workspace-role-assignment
def add_workspace_role_assignment(workspace_id: str, principal_id: str, principal_type: str, role: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/roleAssignments"

    payload = {"principal": {"id": principal_id, "type": principal_type}, "role": role}

    # Make the POST request to provision the identity
    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Workspace role assignment added successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to add workspace role assignment: {response.status_code} - {response.text}")


# Provision workspace identity:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/provision-identity
def provision_workspace_identity(workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/provisionIdentity"

    response = requests.post(url, headers=fabric_headers)

    if response.status_code == 200:
        print(f"[Info] Workspace identity provisioned successfully. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Workspace identity provisioning request submitted. Details: {response.headers}")
        status = poll_long_running_operation(response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to provision identity for workspace.")
    else:
        raise Exception(f"[Error] Failed to provision identity for workspace: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Git Sync Functions
# -----------------------------------------------------------------------------


# Connect workspace to git:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/connect
def connect_workspace_to_git(workspace_id: str, azure_devops_details: dict) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/connect"

    payload = {"gitProviderDetails": azure_devops_details}

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 200:
        print("[Info] Workspace connected to the git repository.")
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "WorkspaceAlreadyConnectedToGit":
            print(f"[Info] Workspace is already connected to git. Response: {response.text}")
        else:
            raise Exception(f"[Error] Failed to connect the workspace to git: {response.status_code} - {response.text}")


# Initialize git connection:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/initialize-connection
def initialize_connection(workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/initializeConnection"

    payload = {"initializationStrategy": "PreferRemote"}

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] The Git connection has been successfully initialized. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Git connection initialization request submitted. Details: {response.headers}")
        status = poll_long_running_operation(response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to initialize the git connection.")
    else:
        raise Exception(f"[Error] Failed to initialize the git connection: {response.status_code} - {response.text}")


# Get workspace git status:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/get-status
def get_workspace_git_status(workspace_id: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/status"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 202:
        print(f"[Info] Get git status request submitted. Details: {response.headers}")
        status = poll_long_running_operation(response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to retrieve git status.")

        return get_operation_result(response.headers)
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "WorkspaceNotConnectedToGit":
            print(f"[Info] Workspace is not connected to git. Response: {response.text}")
            return None
        else:
            raise Exception(f"[Error] Failed to retrieve git status: {response.status_code} - {response.text}")


# Update workspace from git:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/update-from-git
def update_workspace_from_git(workspace_id: str, commit_hash: str, workspace_head: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/updateFromGit"

    payload = {
        "remoteCommitHash": commit_hash,
        "workspaceHead": workspace_head,
        "updateStrategy": "PreferRemote",
        "conflictResolution": {"conflictResolutionType": "Workspace", "conflictResolutionPolicy": "PreferRemote"},
        "options": {"allowOverrideItems": True},
    }

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] Workspace updated from git successfully. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Workspace update from git is in progress. Details: {response.headers}")
        status = poll_long_running_operation(response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to update workspace from git.")
    else:
        raise Exception(f"[Error] Failed to update workspace from git: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Custom pool functions
# -----------------------------------------------------------------------------


# Create workspace custom pool:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/create-workspace-custom-pool
def create_workspace_custom_pool(workspace_id: str, custom_pool_details: dict) -> str:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.post(url, headers=fabric_headers, data=json.dumps(custom_pool_details))

    if response.status_code == 201:
        print(f"[Info] Workspace custom pool created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(f"[Error] Failed to create workspace custom pool: {response.status_code} - {response.text}")


# Update staging settings:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/update-staging-settings
def update_spark_pool(workspace_id: str, environment_id: str, custom_pool_name: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/sparkcompute"

    payload = {"instancePool": {"name": custom_pool_name, "type": "Workspace"}}

    response = requests.patch(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] Spark pool updated successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to update spark pool: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# ADLS shortcut functions
# -----------------------------------------------------------------------------


# Create connection:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/create-connection
def create_adls_cloud_connection(connection_name: str, storage_account_url: str, storage_container_name: str) -> str:

    url = f"{fabric_api_endpoint}/connections"

    payload = {
        "connectionDetails": {
            "type": "AzureDataLakeStorage",
            "creationMethod": "AzureDataLakeStorage",
            "parameters": [
                {"dataType": "text", "name": "server", "value": storage_account_url},
                {"dataType": "text", "name": "path", "value": storage_container_name},
            ],
        },
        "connectivityType": "ShareableCloud",
        "credentialDetails": {
            "credentials": {"credentialType": "WorkspaceIdentity"},
            "singleSignOnType": "None",
            "connectionEncryption": "NotEncrypted",
            "skipTestConnection": False,
        },
        "displayName": connection_name,
        "privacyLevel": "Organizational",
    }

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Connection '{connection_name}' created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(
            f"[Error] Failed to create connection '{connection_name}': {response.status_code} - {response.text}"
        )


# Add connection role assignment:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/add-connection-role-assignment
def add_connection_role_assignment(connection_id: str, principal_id: str, principal_type: str, role: str) -> None:

    url = f"{fabric_api_endpoint}/connections/{connection_id}/roleAssignments"

    payload = {"principal": {"id": principal_id, "type": principal_type}, "role": role}

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Connection role assignment added successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to add connection role assignment: {response.status_code} - {response.text}")


# Create role assignments:
# https://learn.microsoft.com/en-us/rest/api/authorization/role-assignments/create?view=rest-authorization-2022-04-01
def add_storage_account_role_assignments(principal_id: str, scope: str, role_definition_id: str) -> None:

    role_assignment_id = str(uuid.uuid4())
    api_version = "2022-04-01"

    url = (
        f"https://management.azure.com{scope}/providers/Microsoft.Authorization/"
        f"roleAssignments/{role_assignment_id}?api-version={api_version}"
    )

    payload = {
        "properties": {
            "roleDefinitionId": role_definition_id,
            "principalId": principal_id,
            "principalType": "ServicePrincipal",
        }
    }

    response = requests.put(url, headers=azure_management_headers, data=json.dumps(payload))

    if response.status_code == 200 or response.status_code == 201:
        print(f"[Info] Storage account role assignment added successfully. Response: {response.text}")
    else:
        response_json = response.json()
        error_code = response_json.get("error").get("code")
        if error_code == "RoleAssignmentExists":
            print(f"[Info] Role Assignment already exists. Response: {response.text}")
        else:
            raise Exception(
                f"[Error] Failed to add storage account role assignment: {response.status_code} - {response.text}"
            )


def get_storage_container(storage_account_name: str, storage_container_name: str) -> Optional[CaseInsensitiveDict]:

    url = f"https://{storage_account_name}.blob.core.windows.net/{storage_container_name}?restype=container"

    response = requests.get(url, headers=azure_storage_headers)

    if response.status_code == 200:
        return response.headers
    elif response.status_code == 404:
        print(f"[Info] Storage container '{storage_container_name}' not found. Response: {response.text}")
        return None
    else:
        raise Exception(
            f"[Error] Failed to retrieve storage container '{storage_container_name}': "
            f"{response.status_code} - {response.text}"
        )


def create_storage_container(storage_account_name: str, storage_container_name: str) -> None:

    url = f"https://{storage_account_name}.blob.core.windows.net/{storage_container_name}?restype=container"

    response = requests.put(url, headers=azure_storage_headers)

    if response.status_code == 201:
        # Wait until storage container is created
        max_retries = 12  # Retry for a maximum of 1 minute (12 * 5 seconds)
        retries = 0

        storage_container = None
        while storage_container is None and retries < max_retries:
            storage_container = get_storage_container(storage_account_name, storage_container_name)
            print(
                f"[Info] Waiting for storage container '{storage_container_name}' to be created. Retry: {retries + 1}"
            )
            time.sleep(5)
            retries += 1

        if storage_container is None:
            raise Exception(
                f"[Error] Failed to create storage container '{storage_container_name}' after {max_retries * 5} seconds"
            )

        print(
            f"[Info] Storage container '{storage_container_name}' created successfully. Response: {storage_container}"
        )
    else:
        raise Exception(
            f"[Error] Failed to create storage container '{storage_container_name}':"
            f"{response.status_code} - {response.text}"
        )


# Create shortcut:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/onelake-shortcuts/create-shortcut
def create_shortcut(workspace_id: str, item_id: str, shortcut_path: str, shortcut_name: str, target: dict) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items/{item_id}/shortcuts"

    payload = {"name": shortcut_name, "path": shortcut_path, "target": target}

    response = requests.post(url, headers=fabric_headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Shortcut '{shortcut_name}' created successfully. Response: {response.text}")
    else:
        raise Exception(
            f"[Error] Failed to create shortcut '{shortcut_name}': {response.status_code} - {response.text}"
        )


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    set_azure_management_headers(azure_management_bearer_token)
    set_azure_storage_headers(azure_storage_bearer_token)
    set_fabric_headers(fabric_bearer_token)

    capacity_id = get_capacity_id(fabric_capacity_name)
    if capacity_id:
        print(f"[Info] Capacity details: '{fabric_capacity_name}' ({capacity_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve capacity ID for '{fabric_capacity_name}'")

    print("[Info] ############ Workspace Creation ############")

    workspace_id = get_workspace_id(fabric_workspace_name)
    if workspace_id:
        print(f"[Info] Workspace '{fabric_workspace_name}' already exists.")
    else:
        print(f"[Info] Workspace '{fabric_workspace_name}' doesn't exist. Creating workspace.")

        workspace_id = create_workspace(fabric_workspace_name, capacity_id)
        add_workspace_role_assignment(workspace_id, fabric_workspace_group_admin, "Group", "Admin")
        provision_workspace_identity(workspace_id)

    print(f"[Info] Workspace details: '{fabric_workspace_name}' ({workspace_id})")

    print("[Info] ############ Syncing workspace to git ############")

    git_status = get_workspace_git_status(workspace_id)
    if not git_status:
        print("[Info] Workspace is not connected to git. Connecting to git.")
        # Azure DevOps details
        azure_devops_details = {
            "gitProviderType": "AzureDevOps",
            "organizationName": organization_name,
            "projectName": project_name,
            "repositoryName": repo_name,
            "branchName": feature_branch,
            "directoryName": fabric_workspace_directory,
        }
        connect_workspace_to_git(workspace_id, azure_devops_details)
        initialize_connection(workspace_id)
        workspace_head = None
    else:
        workspace_head = git_status["workspaceHead"]

    update_workspace_from_git(workspace_id, commit_hash, workspace_head)

    print("[Info] ############ Creating spark custom pool ############")

    environment_id = get_environment_id(workspace_id, fabric_environment_name)

    if environment_id:
        print(f"[Info] Environment details: '{fabric_environment_name}' ({environment_id})")
    else:
        print(f"[Error] Failed to retrieve environment id for '{fabric_environment_name}'")
        exit(1)

    # Spark compute settings
    env_files_dir = os.path.join(os.path.dirname(__file__), "../../fabric/fabric_environment")
    custom_pool_id = get_custom_pool_id(workspace_id, fabric_custom_pool_name)

    if custom_pool_id:
        print(f"[Info] Custom pool '{fabric_custom_pool_name}' already exists.")
    else:
        print(f"[Info] Custom pool '{fabric_custom_pool_name}' doesn't exist. Creating custom pool.")

        yaml_file_path = os.path.join(env_files_dir, "spark_pool_settings.yml")
        with open(yaml_file_path, "r") as file:
            custom_pool_details = yaml.safe_load(file)
        custom_pool_details["name"] = fabric_custom_pool_name

        create_workspace_custom_pool(workspace_id, custom_pool_details)
        update_spark_pool(workspace_id, environment_id, fabric_custom_pool_name)

    print(f"[Info] Custom pool details: '{fabric_custom_pool_name}' ({custom_pool_id})")

    print("[Info] ############ Creating ADLS shortcut ############")

    # Creating storage container
    storage_container = get_storage_container(storage_account_name, storage_container_name)
    if storage_container:
        print(f"[Info] Storage container '{storage_container_name}' already exists. Response: {storage_container}")
    else:
        print(f"[Info] Storage container '{storage_container_name}' doesn't exist. Creating storage container.")
        create_storage_container(storage_account_name, storage_container_name)

    # Adding role assignment to workspace
    workspace = get_workspace(workspace_id)
    if not workspace:
        print(f"[Error] Failed to retrieve workspace details for '{workspace_id}'")
        exit(1)

    workspace_identity = workspace["workspaceIdentity"]
    scope = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/"
        f"providers/Microsoft.Storage/storageAccounts/{storage_account_name}"
    )
    role_definition_id = (
        f"/subscriptions/{subscription_id}/providers/Microsoft.Authorization/"
        f"roleDefinitions/{storage_account_role_definition_id}"
    )

    add_storage_account_role_assignments(workspace_identity["servicePrincipalId"], scope, role_definition_id)

    # Creating connection
    storage_account_url = f"https://{storage_account_name}.dfs.core.windows.net"

    connection_id = get_connection_id(fabric_connection_name)
    if connection_id:
        print(f"[Info] Connection '{fabric_connection_name}' already exists.")
    else:
        print(f"[Info] Connection '{fabric_connection_name}' doesn't exist. Creating connection.")
        connection_id = create_adls_cloud_connection(
            fabric_connection_name, storage_account_url, storage_container_name
        )
        add_connection_role_assignment(connection_id, fabric_workspace_group_admin, "Group", "Owner")

    # Creating shortcut
    lakehouse_id = get_item_id(workspace_id, "Lakehouse", fabric_lakehouse_name)
    if lakehouse_id:
        print(f"[Info] Lakehouse details: '{fabric_lakehouse_name}' ({lakehouse_id})")

        if get_shortcut(workspace_id, lakehouse_id, "Files", fabric_shortcut_name):
            print(f"[Info] Shortcut '{fabric_shortcut_name}' already exists.")
        else:
            print(f"[Info] Shortcut '{fabric_shortcut_name}' doesn't exist. Creating shortcut.")
            target = {
                "adlsGen2": {
                    "connectionId": connection_id,
                    "location": storage_account_url,
                    "subpath": storage_container_name,
                }
            }
            create_shortcut(workspace_id, lakehouse_id, "Files", fabric_shortcut_name, target)
    else:
        print(f"[Error] Failed to retrieve lakehouse id for '{fabric_lakehouse_name}'")
        exit(1)
