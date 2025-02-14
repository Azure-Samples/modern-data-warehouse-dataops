## python3 setup_fabric_environment.py --workspace_name "" --environment_name "" --bearer_token "${FABRIC_TOKEN}"
import argparse
import json
import os
import time
from typing import Optional

import requests

enable_polling: bool = True


def display_usage() -> None:
    print(
        "Usage: python setup_fabric_environment.py "
        "--workspace_name <workspace_name> "
        "-environment_name <environment_name> "
        "--bearer_token <bearer_token>"
    )


def parse_arguments() -> tuple:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace_name", help="Fabric workspace name")
    parser.add_argument("--environment_name", help="Fabric environment name")
    parser.add_argument("--bearer_token", help="Fabric bearer token")
    args = parser.parse_args()

    workspace_name = args.workspace_name
    environment_name = args.environment_name
    fabric_bearer_token = args.bearer_token

    if not workspace_name or not environment_name or not fabric_bearer_token:
        display_usage()
        exit(1)

    return workspace_name, environment_name, fabric_bearer_token


headers: dict[str, str] = {}
fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"


def validate_token(fabric_bearer_token: str) -> None:
    validation_url = f"{fabric_api_endpoint}/workspaces"
    response = requests.get(validation_url, headers=headers)

    if response.status_code == 200:
        print("[Info] Fabric token is valid.")
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "TokenExpired":
            print("[Error] Fabric token has expired.")
        else:
            print("[Error] Failed to validate Fabric token.")
            print(f"[Error] {response_json}")
        exit(1)


def pretty_print_json(json_data: dict) -> None:
    print(json.dumps(json_data, indent=4))


def set_headers(fabric_bearer_token: str) -> None:
    global headers
    headers = {"Authorization": f"Bearer {fabric_bearer_token}", "Content-Type": "application/json"}


def get_env_spark_libraries_status(workspace_id: str, environment_id: str) -> str:
    environment_status_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}"
    response = requests.get(environment_status_url, headers=headers)

    if response.status_code == 200:
        json_data = response.json()
        return json_data["properties"]["publishDetails"]["componentPublishInfo"]["sparkLibraries"]["state"]
    else:
        print(f"[Error] Failed to retrieve environment status: {response.status_code} - {response.text}")
        exit(1)


def poll_long_running_operation(response_headers: dict) -> None:
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
                raise Exception("[Error] Long running operation failed.")
            else:
                print("[Info] Long running operation in progress.")
                time.sleep(int(retry_after))
        else:
            raise Exception(f"[Error] Failed to retrieve operation status: {response.status_code} - {response.text}")


def get_workspace_id(workspace_name: str) -> Optional[str]:
    get_workspaces_url = f"{fabric_api_endpoint}/workspaces"
    response = requests.get(get_workspaces_url, headers=headers)

    if response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve workspaces: {response.status_code} - {response.text}")

    workspaces = response.json().get("value", [])

    for workspace in workspaces:
        if workspace.get("displayName") == workspace_name:
            return workspace.get("id")
    return None


def get_environment_id(workspace_id: str, environment_name: str) -> Optional[str]:
    get_environments_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments"
    response = requests.get(get_environments_url, headers=headers)

    if response.status_code != 200:
        raise Exception(f"[Error] Failed to retrieve environments: {response.status_code} - {response.text}")

    environments = response.json().get("value", [])

    for environment in environments:
        if environment.get("displayName") == environment_name:
            return environment.get("id")
    return None


def upload_staging_libraries(
    workspace_id: str, environment_id: str, file_path: str, file_name: str, content_type: str
) -> None:
    staging_libraries_url = (
        f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/libraries"
    )
    payload: dict[str, str] = {}
    files = {"file": (file_name, open(os.path.join(file_path, file_name), "rb"), content_type)}
    file_headers = headers
    file_headers.pop("Content-Type", None)
    response = requests.post(staging_libraries_url, headers=file_headers, files=files, data=payload)

    if response.status_code == 200:
        print(f"[Info] Staging libraries uploaded from file '{file_name}' successfully.")
    else:
        raise Exception(
            f"[Error] Staging libraries upload from file '{file_name}' failed: {response.status_code} - {response.text}"
        )


def publish_environment(workspace_id: str, environment_id: str) -> None:
    publish_environment_url = (
        f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/publish"
    )
    response = requests.post(publish_environment_url, headers=headers)

    if response.status_code == 200:
        print("[Info] Environment publishing request submitted successfully.")
    elif response.status_code == 202:
        print("[Info] Environment publishing is in progress.")
        poll_long_running_operation(response.headers)
    else:
        raise Exception(f"[Error] Failed to publish environment: {response.status_code} - {response.text}")


def get_libraries(workspace_id: str, environment_id: str, status: str) -> None:
    if status == "published":
        libraries_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/libraries"
    elif status == "staging":
        libraries_url = (
            f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/libraries"
        )
    else:
        raise Exception(f"[Error] Invalid status: {status}")
    print(f"[Info] Retrieving information about '{status}' libraries.")

    response = requests.get(libraries_url, headers=headers)

    if response.status_code == 200:
        pretty_print_json(response.json())
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "EnvironmentLibrariesNotFound":
            print(f"[Warning] The environment does not have any '{status}' libraries.")
        else:
            print(f"[Error] Failed to retrieve '{status}' libraries.")
            print(f"[Error] {response_json}")


if __name__ == "__main__":

    workspace_name, environment_name, fabric_bearer_token = parse_arguments()

    # Setting request headers
    set_headers(fabric_bearer_token)
    # Validating token
    validate_token(fabric_bearer_token)

    # Getting workspace id
    workspace_id = get_workspace_id(workspace_name)
    if workspace_id:
        print(f"[Info] Workspace details: '{workspace_name}' ({workspace_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve workspace id for '{workspace_name}'")

    # Getting environment id
    environment_id = get_environment_id(workspace_id, environment_name)
    if environment_id:
        print(f"[Info] Environment details: '{environment_name}' ({environment_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve environment id for '{environment_name}'")

    # Uploading "environment.yml" to staging
    upload_staging_libraries(
        workspace_id,
        environment_id,
        "./../fabric/fabric_environment",
        "environment.yml",
        "multipart/form-data",
    )

    # Uploading python library file to staging
    upload_staging_libraries(
        workspace_id,
        environment_id,
        "./../libraries/src",
        "otel_monitor_invoker.py",
        "application/x-python-wheel",
    )

    # Uploading python library file to staging
    upload_staging_libraries(
        workspace_id,
        environment_id,
        "./../libraries/src",
        "ddo_transform_standardize.py",
        "application/x-python-wheel",
    )

    # Uploading python library file to staging
    upload_staging_libraries(
        workspace_id,
        environment_id,
        "./../libraries/src",
        "ddo_transform_transform.py",
        "application/x-python-wheel",
    )

    # Publishing environment (publishing the staged changes)
    publish_environment(workspace_id, environment_id)

    if enable_polling:
        # Polling environment status
        while get_env_spark_libraries_status(workspace_id, environment_id).lower() in ["running", "waiting"]:
            print("[Info] Environment publishing is in progress.")
            time.sleep(60)
        print("[Info] Environment publishing completed.")
        get_libraries(workspace_id, environment_id, status="published")
    else:
        get_libraries(workspace_id, environment_id, status="staging")
