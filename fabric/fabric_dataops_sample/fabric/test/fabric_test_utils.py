import os
import time
from typing import Optional

import requests
from requests.structures import CaseInsensitiveDict

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------

fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")
fabric_headers = {"Authorization": f"Bearer {fabric_bearer_token}", "Content-Type": "application/json"}


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


# Run on-demand item job:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/job-scheduler/run-on-demand-item-job
def run_job(workspace_id: str, item_id: str, jobType: str, payload: dict) -> str:

    url = f"{fabric_api_endpoint}/workspaces/{workspace_id}/items/{item_id}/" f"jobs/instances?jobType={jobType}"

    response = requests.post(url, headers=fabric_headers, json=payload)

    if response.status_code == 202:
        print(f"[Info] Job item triggered successfully. Details: {response.headers}")
        return poll_item_job(response.headers)
    else:
        raise Exception(f"[Error] Failed to trigger job item: {response.status_code} - {response.text}")


# Get item job instance
# https://learn.microsoft.com/en-us/rest/api/fabric/core/job-scheduler/get-item-job-instance
def poll_item_job(response_headers: CaseInsensitiveDict) -> str:
    location = response_headers.get("Location")
    retry_after = response_headers.get("Retry-After")

    print(f"[Info] Polling item job{location}' every '{retry_after}' seconds.")
    time.sleep(int(retry_after) if retry_after else 0)

    while True:

        response = requests.get(location, headers=fabric_headers)

        if response.status_code == 200:

            job_status = response.json().get("status")
            if job_status in ["Cancelled", "Completed", "Deduped", "Failed"]:
                print(f"[Info] Job item details: {response.json()}.")
                return job_status
            else:
                print(f"[Info] Job item status: {job_status}.")
                time.sleep(int(retry_after) if retry_after else 0)
        else:
            raise Exception(f"[Error] Failed to retrieve job item status: {response.status_code} - {response.text}")
