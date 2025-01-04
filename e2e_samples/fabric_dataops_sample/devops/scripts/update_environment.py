import json
import os
import time
from typing import Dict, Optional

import requests
import yaml
from dotenv import load_dotenv

load_dotenv()

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Access Token
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")

# Fabric
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_environment_name = os.environ.get("FABRIC_ENVIRONMENT_NAME")
fabric_custom_pool_name = os.environ.get("FABRIC_CUSTOM_POOL_NAME")

# Process Flags
update_public_libraries = os.environ.get("UPDATE_PUBLIC_LIBRARIES", "False").lower() == "true"
update_custom_libraries = os.environ.get("UPDATE_CUSTOM_LIBRARIES", "False").lower() == "true"

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
fabric_headers: Dict[str, str] = {}

fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"


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
    if not fabric_bearer_token:
        error_list.append("FABRIC_BEARER_TOKEN")

    # Fabric
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_environment_name:
        error_list.append("FABRIC_ENVIRONMENT_NAME")
    if not fabric_custom_pool_name:
        error_list.append("FABRIC_CUSTOM_POOL_NAME")

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


# List Workspace Custom Pools:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/list-workspace-custom-pools
def get_custom_pool_by_name(workspace_id: str, custom_pool_name: str) -> Optional[dict]:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] No custom pool found. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve custom pools: {response.status_code} - {response.text}")

    custom_pools = response.json().get("value", [])

    for custom_pool in custom_pools:
        if custom_pool.get("name") == custom_pool_name:
            return custom_pool
    return None


# -----------------------------------------------------------------------------
# Update Environment Functions
# -----------------------------------------------------------------------------


# Update workspace custom pool:
# https://learn.microsoft.com/en-us/rest/api/fabric/spark/custom-pools/update-workspace-custom-pool
def update_workspace_custom_pool(workspace_id: str, pool_id: str, custom_pool_details: dict) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/pools/{pool_id}"

    response = requests.patch(url, headers=fabric_headers, data=json.dumps(custom_pool_details))

    if response.status_code == 200:
        print(f"[Info] Workspace custom pool updated successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to create workspace custom pool: {response.status_code} - {response.text}")


# Upload staging library:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/upload-staging-library
def upload_staging_library(
    workspace_id: str, environment_id: str, file_path: str, file_name: str, content_type: str
) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/libraries"

    file_headers = fabric_headers
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
def publish_environment(workspace_id: str, environment_id: str) -> None:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/publish"

    response = requests.post(url, headers=fabric_headers)

    if response.status_code == 200:
        print(f"[Info] Publish operation request has been submitted successfully. Response: {response.text}")
    else:
        raise Exception(f"[Error] Failed to publish environment: {response.status_code} - {response.text}")


# Get environment:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/items/get-environment
def get_publish_environment_status(workspace_id: str, environment_id: str) -> str:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}"

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 200:
        json_data = response.json()
        return json_data["properties"]["publishDetails"]["state"]
    else:
        raise Exception(f"[Error] Failed to get publish environment status: {response.status_code} - {response.text}")


# Get spark compute settings:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/get-staging-settings
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-compute/get-published-settings
def get_spark_compute_settings(workspace_id: str, environment_id: str, status: str) -> Optional[dict]:

    if status == "published":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/sparkcompute"
    elif status == "staging":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/sparkcompute"
    else:
        raise Exception(f"[Error] Invalid status: {status}")

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] The environment does not have any '{status}' spark compute settings. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(
            f"[Error] Failed to retrieve {status} spark compute settings: {response.status_code} - {response.text}"
        )

    return response.json()


# Get libraries:
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/get-staging-libraries
# https://learn.microsoft.com/en-us/rest/api/fabric/environment/spark-libraries/get-published-libraries
def get_libraries(workspace_id: str, environment_id: str, status: str) -> Optional[dict]:

    if status == "published":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/libraries"
    elif status == "staging":
        url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/libraries"
    else:
        raise Exception(f"[Error] Invalid status: {status}")

    response = requests.get(url, headers=fabric_headers)

    if response.status_code == 404:
        print(f"[Info] The environment does not have any '{status}' libraries. Response: {response.text}")
        return None
    elif response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve {status} libraries: {response.status_code} - {response.text}")

    return response.json()


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    set_fabric_headers(fabric_bearer_token)

    workspace_id = get_workspace_id(fabric_workspace_name)
    if not workspace_id:
        raise Exception(f"[Error] Workspace '{fabric_workspace_name}' not found.")

    environment_id = get_environment_id(workspace_id, fabric_environment_name)
    if not environment_id:
        raise Exception(f"[Error] Environment '{fabric_environment_name}' not found.")

    # -----------------------------------------------------------------------------
    # Updating custom pool
    # -----------------------------------------------------------------------------
    current_custom_pool = get_custom_pool_by_name(workspace_id, fabric_custom_pool_name)
    if not current_custom_pool:
        raise Exception(f"[Error] Custom pool '{fabric_custom_pool_name}' not found.")

    # Get latest custom pool details from the environment file
    env_files_dir = os.path.join(os.path.dirname(__file__), "../../fabric/fabric_environment")
    yaml_file_path = os.path.join(env_files_dir, "spark_pool_settings.yml")
    with open(yaml_file_path, "r") as file:
        latest_custom_pool = yaml.safe_load(file)
    latest_custom_pool["id"] = current_custom_pool["id"]
    latest_custom_pool["name"] = fabric_custom_pool_name

    # If the custom pool details are different, update the custom pool
    if current_custom_pool != latest_custom_pool:
        print(f"[Info] Updating custom pool '{fabric_custom_pool_name}' details.")
        update_workspace_custom_pool(workspace_id, current_custom_pool["id"], latest_custom_pool)

    # -----------------------------------------------------------------------------
    # Updating public libraries
    # -----------------------------------------------------------------------------
    if update_public_libraries:
        upload_staging_library(
            workspace_id,
            environment_id,
            env_files_dir,
            "environment.yml",
            "multipart/form-data",
        )

    # -----------------------------------------------------------------------------
    # Updating custom libraries
    # -----------------------------------------------------------------------------
    if update_custom_libraries:
        library_files_dir = os.path.join(os.path.dirname(__file__), "../../libraries/src")

        upload_staging_library(
            workspace_id,
            environment_id,
            library_files_dir,
            "ddo_transform_standardize.py",
            "application/x-python-wheel",
        )

        upload_staging_library(
            workspace_id,
            environment_id,
            library_files_dir,
            "ddo_transform_transform.py",
            "application/x-python-wheel",
        )

        upload_staging_library(
            workspace_id,
            environment_id,
            library_files_dir,
            "otel_monitor_invoker.py",
            "application/x-python-wheel",
        )

    # -----------------------------------------------------------------------------
    # Publishing environment
    # -----------------------------------------------------------------------------
    staging_spark_compute_settings = get_spark_compute_settings(workspace_id, environment_id, "staging")
    staging_libraries = get_libraries(workspace_id, environment_id, "staging")

    published_spark_compute_settings = get_spark_compute_settings(workspace_id, environment_id, "published")
    published_libraries = get_libraries(workspace_id, environment_id, "published")

    if (staging_spark_compute_settings != published_spark_compute_settings) or (
        staging_libraries != published_libraries
    ):
        print("[Info] ############ Publishing environment ############")
        publish_environment(workspace_id, environment_id)

        # Polling environment status
        while get_publish_environment_status(workspace_id, environment_id) == "running":
            print("[Info] Environment publishing is in progress.")
            time.sleep(60)
        print("[Info] Environment publishing completed.")
