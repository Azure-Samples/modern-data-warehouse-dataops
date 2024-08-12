## python3 setup_fabric_environment.py --workspace_name "" --environment_name "" --bearer_token "${FABRIC_TOKEN}"
import requests
import json
import time
import os
import random
import argparse

def display_usage():
    print("Usage: python setup_fabric_environment.py --workspace_name <workspace_name> --environment_name <environment_name> --bearer_token <bearer_token>")

def parse_arguments():
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

headers = {}
fabric_api_endpoint="https://api.fabric.microsoft.com/v1"

def validate_token(fabric_bearer_token):
    validation_url = f"{fabric_api_endpoint}/workspaces"
    response = requests.get(validation_url, headers=headers)

    if response.status_code == 200:
        print("[I] Fabric token is valid.")
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "TokenExpired":
            print("[E] Fabric token has expired.")
        else:
            print(f"[E] Failed to validate Fabric token.")
            print(f"[E] {response_json}")
        exit(1)

def pretty_print_json(json_data):
    print(json.dumps(json_data, indent=4))

def set_headers(fabric_bearer_token):
    global headers
    headers = {
        "Authorization": f"Bearer {fabric_bearer_token}",
        "Content-Type": "application/json"
    }

def poll_long_running_operation(response_headers):
    operation_id = response_headers.get("x-ms-operation-id")
    retry_after = response_headers.get("Retry-After")
    print(f"[I] Polling long running operation with id '{operation_id}' every '{retry_after}' seconds.")
    operation_status_url = f"{fabric_api_endpoint}/operations/{operation_id}"
    while True:
        response = requests.get(operation_status_url, headers=headers)
        if response.status_code == 200:
            operation_status = response.json().get("status")
            if operation_status == "Succeeded":
                print("[I] Long running operation completed successfully.")
                break
            elif operation_status == "Failed":
                print("[E] Long running operation failed.")
                break
            else:
                print("[I] Long running operation in progress.")
                time.sleep(int(retry_after))
        else:
            print(f"[E] Failed to retrieve operation status: {response.status_code} - {response.text}")
            break

def get_workspace_id(workspace_name):
    get_workspaces_url = f"{fabric_api_endpoint}/workspaces"
    response = requests.get(get_workspaces_url, headers=headers)
    
    if response.status_code != 200:
        print(f"[I] Failed to retrieve workspaces: {response.status_code} - {response.text}")
        return None

    workspaces = response.json().get('value', [])

    for workspace in workspaces:
        if workspace.get('displayName') == workspace_name:
            return workspace.get('id')
    return None

def get_environment_id(workspace_id, environment_name):
    get_environments_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments"
    response = requests.get(get_environments_url, headers=headers)
    
    if response.status_code != 200:
        print(f"[I] Failed to retrieve environments: {response.status_code} - {response.text}")
        return None

    environments = response.json().get('value', [])

    for environment in environments:
        if environment.get('displayName') == environment_name:
            return environment.get('id')
    return None

def connect_workspace_to_git(workspace_id, branch_name):
    response = requests.post(workspace_id, headers=headers, json=branch_name)

    if response.status_code == 200:
        print("[I] Workspace updated successfully.")
    elif response.status_code == 202:
        print("[I] Workspace update is in progress.")
        poll_long_running_operation(response.headers)
    else:
        print(f"[E] Failed to update workspace: {response.status_code} - {response.text}")

def upload_staging_libraries (workspace_id, environment_id, file_path, file_name, content_type):
    staging_libraries_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/libraries"
    payload = {}
    files = {
        "file": (file_name, open(os.path.join(file_path, file_name), 'rb'), content_type)
    }
    file_headers = headers
    file_headers.pop("Content-Type", None)
    response = requests.post(staging_libraries_url, headers=file_headers, files=files, data=payload)

    if response.status_code == 200:
        print(f"[I] Staging libraries uploaded from file '{file_name}' successfully.")
    else:
        print(f"[E] Staging libraries upload from file '{file_name}' failed: {response.status_code} - {response.text}")
        print(response.text)

def publish_environment(workspace_id, environment_id):
    publish_environment_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/staging/publish"
    response = requests.post(publish_environment_url, headers=headers)

    if response.status_code == 200:
        print("[I] Environment published successfully.")
    elif response.status_code == 202:
        print("[I] Environment publishing is in progress.")
        poll_long_running_operation(response.headers)
    else:
        print(f"[E] Failed to publish environment: {response.status_code} - {response.text}")

def get_libraries(workspace_id, environment_id, status):
    if status == "published":
        libraries_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/libraries"
    elif status == "staging":
        libraries_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/environments/{environment_id}/{status}/libraries"
    else:
        print(f"[E] Invalid status: {status}")
        return
    print(f"[I] Retrieving information about '{status}' libraries.")

    response = requests.get(libraries_url, headers=headers)

    if response.status_code == 200:
        pretty_print_json(response.json())
    else:
        response_json = response.json()
        error_code = response_json.get("errorCode")
        if error_code == "EnvironmentLibrariesNotFound":
            print(f"[W] The environment does not have any '{status}' libraries.")
        else:
            print(f"[E] Failed to retrieve '{status}' libraries.")
            print(f"[E] {response_json}")

def update_spark_setting(workspace_id, environment_name, runtime_version = "1.2"):
    update_spark_setting_url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/spark/settings"
    payload = {
        "environment": {
            "name": environment_name,
            "runtimeVersion": runtime_version
        },
        "automaticLog": {
            "enabled": True
        }
    }

    response = requests.patch(update_spark_setting_url, headers=headers, json=payload)

    if response.status_code == 200:
        print(f"[I] Spark settings (default environment) updated successfully for the workspace.")
    else:
        print(f"[E] Failed to update Spark settings: {response.status_code} - {response.text}")

if __name__ == "__main__":

    workspace_name, environment_name, fabric_bearer_token = parse_arguments()

    set_headers(fabric_bearer_token)
    validate_token(fabric_bearer_token)

    workspace_id = get_workspace_id(workspace_name)
    if workspace_id:
        print(f"[I] Workspace details: '{workspace_name}' ({workspace_id})")
    else:
        print(f"[E] Failed to retrieve workspace id for '{workspace_name}'")
        exit(1)

    environment_id = get_environment_id(workspace_id, environment_name)
    if environment_id:
        print(f"[I] Environment details: '{environment_name}' ({environment_id})")
    else:
        print(f"[E] Failed to retrieve environment id for '{environment_name}'")
        exit(1)

    upload_staging_libraries (workspace_id, environment_id, "./../../config/fabric_environment", "environment.yml", "multipart/form-data")
    upload_staging_libraries (workspace_id, environment_id, "./../../config/fabric_environment", "azure_monitor_opentelemetry-1.6.1-py3-none-any.whl", "application/x-python-wheel")

    publish_environment(workspace_id, environment_id)

    get_libraries(workspace_id, environment_id, status="published")
    get_libraries(workspace_id, environment_id, status="staging")

    update_spark_setting(workspace_id, environment_name, runtime_version = "1.2")
