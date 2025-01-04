import base64
import os

import requests
from requests.auth import HTTPBasicAuth

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
org = os.environ.get("GIT_ORGANIZATION_NAME")
project = os.environ.get("GIT_PROJECT_NAME")
repo = os.environ.get("GIT_REPOSITORY_NAME")
branch_name = os.environ.get("GIT_BRANCH_NAME")
directory = os.environ.get("GIT_DIRECTORY_NAME")
username = os.environ.get("GIT_USERNAME")
token = os.environ.get("GIT_TOKEN")

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
base_url = f"https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}"
auth = HTTPBasicAuth(username, token)
headers = {"Content-Type": "application/json"}

local_base_dir = os.path.join(os.path.dirname(__file__), "../")


def get_latest_commit_id() -> str:

    url = f"{base_url}/commits?searchCriteria.itemVersionVersion={branch_name}&$top=1&api-version=7.1-preview.1"

    response = requests.get(url, auth=auth, headers=headers)

    if response.status_code == 200:
        commits = response.json()
        if commits.get("value"):
            commit_id = commits["value"][0]["commitId"]
            return commit_id
        else:
            print(f"[Info] No commits found for branch {branch_name}.")
            return "0000000000000000000000000000000000000000"
    else:
        raise Exception(
            f"[Error] Failed to fetch commit for branch {branch_name}: {response.status_code} - {response.text}"
        )


def add_file(target_path: str, local_file_path: str) -> dict:

    local_file_path = os.path.abspath(os.path.join(local_base_dir, local_file_path))

    with open(local_file_path, "rb") as file:
        content = base64.b64encode(file.read()).decode("utf-8")

    return {
        "changeType": "Add",
        "item": {"path": f"{directory}/{target_path}"},
        "newContent": {"content": content, "contentType": "base64encoded"},
    }


def commit_push(commit_message: str, changes: list) -> dict:
    old_object_id = get_latest_commit_id()

    # Prepare commit data with all changes
    commit_data = {
        "refUpdates": [{"name": f"refs/heads/{branch_name}", "oldObjectId": old_object_id}],
        "commits": [{"comment": commit_message, "changes": changes}],
    }

    # Push the commit
    response = requests.post(
        f"{base_url}/pushes?api-version=7.2-preview.3", auth=auth, headers=headers, json=commit_data
    )

    if response.status_code != 201:
        raise Exception(f"[Error] Failed to push commit: {response.status_code} - {response.text}")

    # Return commit response

    return response.json()


def copy_directory(target_path: str, local_file_path: str) -> list:
    changes = []
    for item in os.listdir(local_file_path):
        # Ignore unwanted files
        if item in [".DS_Store", "Thumbs.db", "desktop.ini"]:
            continue
        if os.path.isfile(os.path.join(local_file_path, item)):
            changes.append(add_file(f"{target_path}/{item}", f"{local_file_path}/{item}"))
        else:
            changes.extend(copy_directory(f"{target_path}/{item}", f"{local_file_path}/{item}"))
    return changes


# Main function to orchestrate the process
def main() -> None:

    # config
    changes = copy_directory("config", "config")
    response = commit_push(commit_message="Add config files", changes=changes)
    print(f"[Info] Commit response: {response}")

    # data
    changes = copy_directory("data", "data")
    response = commit_push(commit_message="Add seed data files", changes=changes)
    print(f"[Info] Commit response: {response}")

    # devops
    changes = copy_directory("devops", "devops")
    response = commit_push(commit_message="Add ci/cd files", changes=changes)
    print(f"[Info] Commit response: {response}")

    # fabric
    changes = copy_directory("fabric", "fabric")
    changes.append(
        {
            "changeType": "Add",
            "item": {"path": f"{directory}/fabric/workspace/README.md"},
            "newContent": {"content": "", "contentType": "rawtext"},
        }
    )  # Adding an empty file to create the fabric workspace folder
    response = commit_push(commit_message="Add fabric files", changes=changes)
    print(f"[Info] Commit response: {response}")

    # libraries
    changes = copy_directory("libraries", "libraries")
    response = commit_push(commit_message="Add library files", changes=changes)
    print(f"[Info] Commit response: {response}")


if __name__ == "__main__":
    main()
