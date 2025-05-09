import json
import os
import subprocess
import time
import uuid
from typing import Dict, List, Optional, Tuple

import requests
from requests.structures import CaseInsensitiveDict

fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"
azure_management_api_endpoint = "https://management.azure.com"

# -----------------------------------------------------------------------------
# Workspace Functions
# -----------------------------------------------------------------------------


# List workspaces:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/list-workspaces
def get_workspace_id(headers: dict, workspace_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        workspaces = response.json().get("value", [])

        for workspace in workspaces:
            if workspace.get("displayName") == workspace_name:
                return workspace.get("id")
        return None
    elif response.status_code == 404:
        print(f"[Info] No workspaces found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve workspaces: {response.status_code} - {response.text}")


# Get Workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/get-workspace
def get_workspace(headers: dict, workspace_id: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        print(f"[Info] Workspace not found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve workspace: {response.status_code} - {response.text}")


# Create workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/create-workspace
def create_workspace(headers: dict, workspace_name: str, capacity_id: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces"

    payload = {
        "displayName": workspace_name,
        "capacityId": capacity_id,
        "description": f"Workspace {workspace_name}",
    }

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Workspace '{workspace_name}' created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(
            f"[Error] Failed to create workspace '{workspace_name}': {response.status_code} - {response.text}"
        )


# Delete workspace:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/delete-workspace
def delete_workspace(headers: dict, workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}"

    response = requests.delete(url, headers=headers)

    if response.status_code == 200:
        print("[Info] Workspace deleted successfully.")
    else:
        raise Exception(f"[Error] Failed to delete workspace': {response.status_code} - {response.text}")


# Add workspace role assignments:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/add-workspace-role-assignment
def add_workspace_role_assignment(
    headers: dict, workspace_id: str, principal_id: str, principal_type: str, role: str
) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/roleAssignments"

    payload = {"principal": {"id": principal_id, "type": principal_type}, "role": role}

    # Make the POST request to provision the identity
    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Workspace role assignment added successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to add workspace role assignment: {response.status_code} - {response.text}")


# Provision workspace identity:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/workspaces/provision-identity
def provision_workspace_identity(headers: dict, workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/provisionIdentity"

    response = requests.post(url, headers=headers)

    if response.status_code == 200:
        print(f"[Info] Workspace identity provisioned successfully. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Workspace identity provisioning request submitted. Details: {response.headers}")
        status = poll_long_running_operation(headers, response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to provision identity for workspace.")
    else:
        raise Exception(f"[Error] Failed to provision identity for workspace: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Workspace Items Functions
# -----------------------------------------------------------------------------


# List items:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/items/list-items
def get_item_id(headers: dict, workspace_id: str, type: str, item_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        items = response.json().get("value", [])

        for item in items:
            if item.get("displayName") == item_name and item.get("type") == type:
                return item.get("id")
        return None
    elif response.status_code == 404:
        print(f"[Info] No items found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve items: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Shortcut Functions
# -----------------------------------------------------------------------------


# Get shortcut:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/onelake-shortcuts/get-shortcut
def get_shortcut(
    headers: dict, workspace_id: str, item_id: str, shortcut_path: str, shortcut_name: str
) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items/{item_id}/shortcuts/{shortcut_path}/{shortcut_name}"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        print(f"[Info] Shortcut not found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve shortcuts: {response.status_code} - {response.text}")


# Create shortcut:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/onelake-shortcuts/create-shortcut
def create_shortcut(
    headers: dict, workspace_id: str, item_id: str, shortcut_path: str, shortcut_name: str, target: dict
) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items/{item_id}/shortcuts"

    payload = {"name": shortcut_name, "path": shortcut_path, "target": target}

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Shortcut '{shortcut_name}' created successfully. Response: {response.text}")
    else:
        raise Exception(
            f"[Error] Failed to create shortcut '{shortcut_name}': {response.status_code} - {response.text}"
        )


# -----------------------------------------------------------------------------
# Environments Functions
# -----------------------------------------------------------------------------


# List Environments:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/items/list-environments
def get_environment_id(headers: dict, workspace_id: str, environment_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        environments = response.json().get("value", [])

        for environment in environments:
            if environment.get("displayName") == environment_name:
                return environment.get("id")
        return None

    elif response.status_code == 404:
        print(f"[Info] No environments found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve environments: {response.status_code} - {response.text}")


# Get environment:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/items/get-environment
def get_publish_environment_status(headers: dict, workspace_id: str, environment_id: str) -> str:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        json_data = response.json()
        return json_data["properties"]["publishDetails"]["state"]
    else:
        raise Exception(f"[Error] Failed to get publish environment status: {response.status_code} - {response.text}")


# Get spark compute settings:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/get-staging-settings
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/get-published-settings
def get_spark_compute_settings(headers: dict, workspace_id: str, environment_id: str, status: str) -> Optional[dict]:

    if status == "published":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/sparkcompute"
    elif status == "staging":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/sparkcompute"
    else:
        raise Exception(f"[Error] Invalid status: {status}")

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        print(f"[Info] The environment does not have any '{status}' spark compute settings. Response: {response.text}")
        return None
    else:
        raise Exception(
            f"[Error] Failed to retrieve {status} spark compute settings: {response.status_code} - {response.text}"
        )


# Get libraries:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/get-staging-libraries
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/get-published-libraries
def get_libraries(headers: dict, workspace_id: str, environment_id: str, status: str) -> Optional[dict]:

    if status == "published":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/libraries"
    elif status == "staging":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/libraries"
    else:
        raise Exception(f"[Error] Invalid status: {status}")

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        print(f"[Info] The environment does not have any '{status}' libraries. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve {status} libraries: {response.status_code} - {response.text}")


# Upload staging library:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/upload-staging-library
def upload_staging_library(
    headers: dict, workspace_id: str, environment_id: str, file_path: str, file_name: str, content_type: str
) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/libraries"

    file_headers = headers
    file_headers.pop("Content-Type", None)
    files = {"file": (file_name, open(os.path.join(file_path, file_name), "rb"), content_type)}

    response = requests.post(url, headers=file_headers, files=files)

    if response.status_code == 200:
        print(f"[Info] Staging libraries uploaded from file '{file_name}' successfully. Response: {response.text}")
    else:
        raise Exception(
            f"[Error] Failed to upload staging libraries upload from file '{file_name}': "
            f"{response.status_code} - {response.text}"
        )


# Publish environment:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/publish-environment
def publish_environment(headers: dict, workspace_id: str, environment_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/publish"

    response = requests.post(url, headers=headers)

    if response.status_code == 200:
        print(f"[Info] Publish operation request has been submitted successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to publish environment: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Custom pool functions
# -----------------------------------------------------------------------------


# List workspace custom pools:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/list-workspace-custom-pools
def get_custom_pool_id(headers: dict, workspace_id: str, custom_pool_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        custom_pools = response.json().get("value", [])

        for custom_pool in custom_pools:
            if custom_pool.get("name") == custom_pool_name:
                return custom_pool.get("id")
        return None
    elif response.status_code == 404:
        print(f"[Info] No custom pools found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve custom pool: {response.status_code} - {response.text}")


# List Workspace Custom Pools:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/list-workspace-custom-pools
def get_custom_pool_by_name(headers: dict, workspace_id: str, custom_pool_name: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        custom_pools = response.json().get("value", [])

        for custom_pool in custom_pools:
            if custom_pool.get("name") == custom_pool_name:
                return custom_pool
        return None
    elif response.status_code == 404:
        print(f"[Info] No custom pool found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve custom pools: {response.status_code} - {response.text}")


# Create workspace custom pool:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/create-workspace-custom-pool
def create_workspace_custom_pool(headers: dict, workspace_id: str, custom_pool_details: dict) -> str:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.post(url, headers=headers, data=json.dumps(custom_pool_details))

    if response.status_code == 201:
        print(f"[Info] Workspace custom pool created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(f"[Error] Failed to create workspace custom pool: {response.status_code} - {response.text}")


# Update workspace custom pool:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/update-workspace-custom-pool
def update_workspace_custom_pool(headers: dict, workspace_id: str, pool_id: str, custom_pool_details: dict) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools/{pool_id}"

    response = requests.patch(url, headers=headers, data=json.dumps(custom_pool_details))

    if response.status_code == 200:
        print(f"[Info] Workspace custom pool updated successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to create workspace custom pool: {response.status_code} - {response.text}")


# Update staging settings:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/update-staging-settings
def update_spark_pool(headers: dict, workspace_id: str, environment_id: str, custom_pool_name: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/sparkcompute"

    payload = {"instancePool": {"name": custom_pool_name, "type": "Workspace"}}

    response = requests.patch(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] Spark pool updated successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to update spark pool: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Capacities Functions
# -----------------------------------------------------------------------------


# List Capacities:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/capacities/list-capacities
def get_capacity_id(headers: dict, capacity_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/capacities"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        capacities = response.json().get("value", [])

        for capacity in capacities:
            if capacity.get("displayName") == capacity_name:
                return capacity.get("id")
        return None

    elif response.status_code == 404:
        print(f"[Info] No capacities found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve capacities: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Connections Functions
# -----------------------------------------------------------------------------


# List Connections:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/list-connections
def get_connection_id(headers: dict, connection_name: str) -> Optional[str]:

    url = f"{fabric_api_endpoint}/connections"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        connections = response.json().get("value", [])

        for connection in connections:
            if connection.get("displayName") == connection_name:
                return connection.get("id")
        return None
    elif response.status_code == 404:
        print(f"[Info] No connections found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve connections: {response.status_code} - {response.text}")


# Create connection:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/create-connection
def create_adls_cloud_connection(
    headers: dict, connection_name: str, storage_account_url: str, storage_container_name: str
) -> str:

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

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Connection '{connection_name}' created successfully. Response: {response.text}")
        return response.json().get("id")
    else:
        raise Exception(
            f"[Error] Failed to create connection '{connection_name}': {response.status_code} - {response.text}"
        )


# Delete connection:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/delete-connection
def delete_adls_cloud_connection(headers: dict, connection_id: str) -> None:

    url = f"{fabric_api_endpoint}/connections/{connection_id}"

    response = requests.delete(url, headers=headers)

    if response.status_code == 200:
        print("[Info] Connection deleted successfully.")
    elif response.status_code == 404:
        print("[Info] Connection already deleted or does not exist.")
    else:
        raise Exception(f"[Error] Delete connection failed': {response.status_code} - {response.text}")


# Add connection role assignment:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/add-connection-role-assignment
def add_connection_role_assignment(
    headers: dict, connection_id: str, principal_id: str, principal_type: str, role: str
) -> None:

    url = f"{fabric_api_endpoint}/connections/{connection_id}/roleAssignments"

    payload = {"principal": {"id": principal_id, "type": principal_type}, "role": role}

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 201:
        print(f"[Info] Connection role assignment added successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to add connection role assignment: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Git Functions
# -----------------------------------------------------------------------------


# Connect workspace to git:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/connect
def connect_workspace_to_git(headers: dict, workspace_id: str, azure_devops_details: dict) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/connect"

    payload = {"gitProviderDetails": azure_devops_details}

    response = requests.post(url, headers=headers, data=json.dumps(payload))

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
def initialize_connection(headers: dict, workspace_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/initializeConnection"

    payload = {"initializationStrategy": "PreferRemote"}

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] The Git connection has been successfully initialized. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Git connection initialization request submitted. Details: {response.headers}")
        status = poll_long_running_operation(headers, response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to initialize the git connection.")
    else:
        raise Exception(f"[Error] Failed to initialize the git connection: {response.status_code} - {response.text}")


# Get workspace git status:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/get-status
def get_workspace_git_status(headers: dict, workspace_id: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/status"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 202:
        print(f"[Info] Get git status request submitted. Details: {response.headers}")
        status = poll_long_running_operation(headers, response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to retrieve git status.")

        return get_operation_result(headers, response.headers)
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
def update_workspace_from_git(headers: dict, workspace_id: str, commit_hash: str, workspace_head: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/updateFromGit"

    payload = {
        "remoteCommitHash": commit_hash,
        "workspaceHead": workspace_head,
        "updateStrategy": "PreferRemote",
        "conflictResolution": {"conflictResolutionType": "Workspace", "conflictResolutionPolicy": "PreferRemote"},
        "options": {"allowOverrideItems": True},
    }

    response = requests.post(url, headers=headers, data=json.dumps(payload))

    if response.status_code == 200:
        print(f"[Info] Workspace updated from git successfully. Response: {response.text}")
    elif response.status_code == 202:
        print(f"[Info] Workspace update from git is in progress. Details: {response.headers}")
        status = poll_long_running_operation(headers, response.headers)

        if status != "Succeeded":
            raise Exception("[Error] Failed to update workspace from git.")
    else:
        raise Exception(f"[Error] Failed to update workspace from git: {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Operations Functions
# -----------------------------------------------------------------------------


# Get operation result:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/long-running-operations/get-operation-result
def get_operation_result(headers: dict, response_headers: CaseInsensitiveDict) -> Optional[dict]:

    operation_id = response_headers.get("x-ms-operation-id")

    url = f"{fabric_api_endpoint}/operations/{operation_id}/result"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        print(f"[Info] Operation result not found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve operation result: {response.status_code} - {response.text}")


# Get operation state:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/long-running-operations/get-operation-state
def poll_long_running_operation(headers: dict, response_headers: CaseInsensitiveDict) -> str:
    operation_id = response_headers.get("x-ms-operation-id")
    retry_after = response_headers.get("Retry-After")

    print(f"[Info] Polling long running operation with id '{operation_id}' every '{retry_after}' seconds.")

    url = f"{fabric_api_endpoint}/operations/{operation_id}"

    while True:

        response = requests.get(url, headers=headers)

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
# Azure Management functions
# -----------------------------------------------------------------------------


# List role assignments for scope
# https://learn.microsoft.com/en-us/rest/api/authorization/role-assignments/list-for-scope?view=rest-authorization-2022-04-01
def get_storage_role_assignments(headers: dict, scope: str, principal_id: str) -> List[str]:

    api_version = "2022-04-01"

    url = (
        f"{azure_management_api_endpoint}{scope}/providers/Microsoft.Authorization/"
        f"roleAssignments?api-version={api_version}"
    )

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        role_assignments = response.json().get("value", [])

        role_assignment_ids = []
        for role_assignment in role_assignments:
            if role_assignment.get("properties").get("principalId") == principal_id:
                role_assignment_ids.append(role_assignment.get("id"))
        return role_assignment_ids
    elif response.status_code == 404:
        print("[Info] No storage role assignments found.")
        return []
    else:
        raise Exception(f"[Error] Failed to retrieve role assignments: {response.status_code} - {response.text}")


# Create role assignments:
# https://learn.microsoft.com/en-us/rest/api/authorization/role-assignments/create?view=rest-authorization-2022-04-01
def add_storage_account_role_assignments(headers: dict, principal_id: str, scope: str, role_definition_id: str) -> None:

    role_assignment_id = str(uuid.uuid4())
    api_version = "2022-04-01"

    url = (
        f"{azure_management_api_endpoint}{scope}/providers/Microsoft.Authorization/"
        f"roleAssignments/{role_assignment_id}?api-version={api_version}"
    )

    payload = {
        "properties": {
            "roleDefinitionId": role_definition_id,
            "principalId": principal_id,
            "principalType": "ServicePrincipal",
        }
    }

    response = requests.put(url, headers=headers, data=json.dumps(payload))

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


# Delete role assignments:
# https://learn.microsoft.com/en-us/rest/api/authorization/role-assignments/delete-by-id?view=rest-authorization-2022-04-01
def delete_storage_account_role_assignment(headers: dict, role_assignment_id: str) -> None:

    api_version = "2022-04-01"

    url = f"{azure_management_api_endpoint}/{role_assignment_id}?api-version={api_version}"

    response = requests.delete(url, headers=headers)

    if response.status_code == 200:
        print("[Info] Role assignment deleted successfully.")
    elif response.status_code == 204:
        print("[Info] Role assignment already deleted or does not exist.")
    else:
        raise Exception(f"[Error] Failed to role assignment': {response.status_code} - {response.text}")


# -----------------------------------------------------------------------------
# Azure Storage functions
# -----------------------------------------------------------------------------


def get_storage_container(
    headers: dict, storage_account_name: str, storage_container_name: str
) -> Optional[CaseInsensitiveDict]:

    url = f"https://{storage_account_name}.blob.core.windows.net/{storage_container_name}?restype=container"

    response = requests.get(url, headers=headers)

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


def create_storage_container(headers: dict, storage_account_name: str, storage_container_name: str) -> None:

    url = f"https://{storage_account_name}.blob.core.windows.net/{storage_container_name}?restype=container"

    response = requests.put(url, headers=headers)

    if response.status_code == 201:
        print(f"[Info] Storage container '{storage_container_name}' created successfully. Response: {response.text}")
    else:
        raise Exception(
            f"[Error] Failed to create storage container '{storage_container_name}':"
            f"{response.status_code} - {response.text}"
        )


# Delete storage container:
# https://learn.microsoft.com/en-us/rest/api/storageservices/delete-container
def delete_storage_container(headers: dict, storage_account_name: str, storage_container_name: str) -> None:

    url = f"https://{storage_account_name}.blob.core.windows.net/{storage_container_name}?restype=container"

    response = requests.delete(url, headers=headers)

    if response.status_code == 202:
        print("[Info] Delete container request submitted successfully.")
    elif response.status_code == 404:
        print("[Info] Container already deleted or does not exist.")
    else:
        raise Exception(f"[Error] Delete container request failed': {response.status_code} - {response.text}")


def get_lakehouse_id(headers: dict, workspace_id: str, lakehouse_name: str) -> Optional[str]:
    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        items = response.json().get("value", [])

        for item in items:
            if item.get("displayName") == lakehouse_name and item.get("type") == "Lakehouse":
                return item.get("id")
        print(f"[Info] Lakehouse '{lakehouse_name}' not found.")
        return None
    elif response.status_code == 404:
        print(f"[Info] No items found. Response: {response.text}")
        return None
    else:
        raise Exception(f"[Error] Failed to retrieve items: {response.status_code} - {response.text}")


def get_bearer_tokens_and_headers() -> Tuple[Dict[str, str], Dict[str, str], Dict[str, str], str, str, str]:
    fabric_bearer_token = (
        subprocess.check_output(
            "az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv",
            shell=True,
        )
        .decode("utf-8")
        .strip()
    )

    azure_management_bearer_token = (
        subprocess.check_output(
            "az account get-access-token --resource https://management.azure.com --query accessToken -o tsv",
            shell=True,
        )
        .decode("utf-8")
        .strip()
    )

    azure_storage_bearer_token = (
        subprocess.check_output(
            "az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv",
            shell=True,
        )
        .decode("utf-8")
        .strip()
    )

    azure_management_headers = {
        "Authorization": f"Bearer {azure_management_bearer_token}",
        "Content-Type": "application/json",
    }
    azure_storage_headers = {"Authorization": f"Bearer {azure_storage_bearer_token}", "x-ms-version": "2021-02-12"}
    fabric_headers = {"Authorization": f"Bearer {fabric_bearer_token}", "Content-Type": "application/json"}

    return (
        azure_management_headers,
        azure_storage_headers,
        fabric_headers,
        azure_management_bearer_token,
        azure_storage_bearer_token,
        fabric_bearer_token,
    )
