import json
import os
import random
import string
import time
from typing import Optional

import requests
from dotenv import load_dotenv
from requests.structures import CaseInsensitiveDict

load_dotenv()


class ValidationError(Exception):
    def __init__(self, message: str) -> None:
        self.message = message
        print(f"[Error] {self.message}")
        exit(1)


def validate_env() -> None:
    error_list = []
    if not organization_name:
        error_list.append("ORGANIZATIONAL_NAME")
    if not fabric_project_name:
        error_list.append("FABRIC_PROJECT_NAME")
    if not project_name:
        error_list.append("PROJECT_NAME")
    if not repo_name:
        error_list.append("REPO_NAME")
    if not main_branch:
        error_list.append("MAIN_BRANCH")
    if not feature_branch:
        error_list.append("FEATURE_BRANCH")
    if not account_name:
        error_list.append("ACCOUNT_NAME")
    if not directory_name:
        error_list.append("DIRECTORY_NAME")
    if not fabric_bearer_token:
        error_list.append("FABRIC_BEARER_TOKEN")
    if not capacity_name:
        error_list.append("CAPACITY_NAME")
    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


# Azure Repo Details
organization_name = os.environ.get("ORGANIZATIONAL_NAME")
fabric_project_name = os.environ.get("FABRIC_PROJECT_NAME")
project_name = os.environ.get("PROJECT_NAME")
repo_name = os.environ.get("REPO_NAME")
main_branch = os.environ.get("MAIN_BRANCH")
feature_branch = os.environ.get("FEATURE_BRANCH")
# Environment variables
account_name = os.environ.get("ACCOUNT_NAME")
directory_name = os.environ.get("DIRECTORY_NAME")
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")
capacity_name = os.environ.get("CAPACITY_NAME")
workspace_name = os.environ.get("WORKSPACE_NAME")

headers: dict[str, str] = {}

# Azure DevOps details
azure_devops_details = {
    "gitProviderType": "AzureDevOps",
    "organizationName": organization_name,
    "projectName": project_name,
    "repositoryName": repo_name,
    "branchName": "<branch>",
    "directoryName": directory_name,
}

fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"


def disconnect_workspace(workspace_id: str) -> None:
    # Set the URL for disconnecting the workspace
    disconnect_workspace_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/disconnect"
    disconnect_workspace_body: dict[str, str] = {}
    response = requests.post(disconnect_workspace_url, headers=headers, json=disconnect_workspace_body)

    if response.status_code == 200:
        print("[Info] Workspace disconnected from the git repository.")
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "WorkspaceNotConnectedToGit":
            print("[Info] Workspace is not connected to git.")
        else:
            print("[Error] The workspace disconnection from git failed.")
            print(f"[Error] {response_json}")


def get_workspace_name(project_name: str) -> str:
    random_string = "".join(random.choice(string.ascii_lowercase) for _ in range(5))
    return f"ws-{project_name}-{random_string}"


def set_headers(fabric_bearer_token: str) -> None:
    global headers
    headers = {"Authorization": f"Bearer {fabric_bearer_token}", "Content-Type": "application/json"}


def get_workspace_id(workspace_name: str) -> Optional[str]:
    get_workspaces_url = f"{fabric_api_endpoint}/workspaces"
    response = requests.get(get_workspaces_url, headers=headers)

    if response.status_code != 200:
        print(f"[Info] Failed to retrieve workspaces: {response.status_code} - {response.text}")
        return None

    workspaces = response.json().get("value", [])

    for workspace in workspaces:
        if workspace.get("displayName") == workspace_name:
            return workspace.get("id")
    return None


def create_workspace(workspace_name: str, capacity_id: str) -> None:
    json_payload = {
        "DisplayName": workspace_name,
        "capacityId": capacity_id,
        "description": f"Workspace {workspace_name}",
    }

    response = requests.post(f"{fabric_api_endpoint}/workspaces", headers=headers, data=json.dumps(json_payload))

    if response.status_code == 201:
        print(f"[Info] Workspace '{workspace_name}' created successfully")
    else:
        print(f"[Error] Failed to create workspace '{workspace_name}': {response.status_code} - {response.text}")


def get_capacity_id(capacity_name: str) -> Optional[str]:
    get_capacities_url = f"{fabric_api_endpoint}/capacities"
    response = requests.get(get_capacities_url, headers=headers)

    if response.status_code != 200:
        print(f"[Error] Failed to retrieve capacities: {response.status_code} - {response.text}")
        return None

    capacities = response.json().get("value", [])
    for capacity in capacities:
        if capacity.get("displayName") == capacity_name:
            return capacity.get("id")
    return None


def initialize_connection(workspace_id: str) -> None:
    initialize_connection_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/initializeConnection"
    initialize_connection_body = '{"InitializationStrategy": "PreferRemote"}'

    _ = requests.post(initialize_connection_url, headers=headers, data=initialize_connection_body)

    print("[Info] The Git connection has been successfully initialized.")


def get_workspace_git_status(workspace_id: str) -> dict:
    workspace_git_status_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/status"
    response = requests.get(workspace_git_status_url, headers=headers)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"[Error] Failed to retrieve workspace status: {response.status_code} - {response.text}")
        return {}


def connect_workspace_to_git(workspace_id: str, branch_name: str) -> None:
    connect_workspace_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/connect"
    azure_devops_details["branchName"] = branch_name
    connect_workspace_body = {"gitProviderDetails": azure_devops_details}
    response = requests.post(connect_workspace_url, headers=headers, json=connect_workspace_body)

    if response.status_code == 200:
        print("[Info] Workspace connected to the git repository.")
        initialize_connection(workspace_id)
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "WorkspaceAlreadyConnectedToGit":
            print("[Info] Workspace is already connected to git.")
        else:
            print("[Error] The workspace connection to git failed.")
            print(f"[Error] {response_json}")


def delete_workspace(workspace_id: str) -> None:
    delete_workspace_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}"
    response = requests.delete(delete_workspace_url, headers=headers)

    if response.status_code == 200:
        print("[Info] Workspace deleted successfully.")
    else:
        print(f"[Error] Failed to delete workspace: {response.status_code} - {response.text}")


def poll_long_running_operation(response_headers: CaseInsensitiveDict[str]) -> None:
    operation_id = response_headers.get("x-ms-operation-id")
    retry_after = response_headers.get("Retry-After")
    print(f"[Info] Polling long running operation with id '{operation_id}' every '{retry_after}' seconds.")
    operation_status_url = f"{fabric_api_endpoint}/operations/{operation_id}"
    while True:
        response = requests.get(operation_status_url, headers=headers)
        if response.status_code == 200:
            operation_status = response.json().get("status")
            if operation_status == "Succeeded":
                print("[Info] Long running operation completed successfully.")
                break
            elif operation_status == "Failed":
                print("[Error] Long running operation failed.")
                break
            else:
                print("[Info] Long running operation in progress.")
                time.sleep(int(retry_after) if retry_after else 0)
        else:
            print(f"[Error] Failed to retrieve operation status: {response.status_code} - {response.text}")
            break


def update_workspace_from_git(workspace_id: str) -> None:
    git_status = get_workspace_git_status(workspace_id)
    workspace_head = git_status["workspaceHead"]
    remote_commit_hash = git_status["remoteCommitHash"]

    update_workspace_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/git/updateFromGit"
    update_workspace_body = {"updateStrategy": "PreferRemote"}
    update_workspace_body = {
        "remoteCommitHash": remote_commit_hash,
        "workspaceHead": workspace_head,
        "conflictResolution": {"conflictResolutionType": "Workspace", "conflictResolutionPolicy": "PreferRemote"},
        "options": {"allowOverrideItems": True},
    }
    response = requests.post(update_workspace_url, headers=headers, json=update_workspace_body)

    if response.status_code == 200:
        print("[Info] Workspace updated successfully.")
    elif response.status_code == 202:
        print("[Info] Workspace update is in progress.")
        poll_long_running_operation(response.headers)
    else:
        print(f"[Error] Failed to update workspace: {response.status_code} - {response.text}")


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    if workspace_name == "":
        workspace_name = get_workspace_name(fabric_project_name)
    print(f"[Info] Creating workspace '{workspace_name}' for Fabric project '{fabric_project_name}'")

    set_headers(fabric_bearer_token)

    capacity_id = get_capacity_id(capacity_name)
    if capacity_id:
        print(f"[Info] Capacity details: '{capacity_name}' ({capacity_id})")
    else:
        print(f"[Error] Failed to retrieve capacity id for '{capacity_name}'")
        exit(1)

    workspace_id = get_workspace_id(workspace_name)
    if workspace_id:
        print(f"[Info] Workspace '{workspace_name}' already exists, deleting it.")
        delete_workspace(workspace_id)
    create_workspace(workspace_name, capacity_id)

    workspace_id = get_workspace_id(workspace_name)
    if workspace_id:
        print(f"[Info] Workspace details: '{workspace_name}' ({workspace_id})")
    else:
        print(f"[Error] Failed to retrieve workspace ID for '{workspace_name}'")
        exit(1)

    connect_workspace_to_git(workspace_id, main_branch)
    update_workspace_from_git(workspace_id)

    disconnect_workspace(workspace_id)

    connect_workspace_to_git(workspace_id, feature_branch)
    update_workspace_from_git(workspace_id)
