import argparse

## python3 setup_azdo_repository.py \
# --organization_name "" \
# --project_name "" \
# --repository_name "" \
# --branch_name "" \
# --base_branch_name "" \
# --directory_name "" \
# --username "" \
# --token ""
import base64
import os

import requests
from requests.auth import HTTPBasicAuth

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
base_url = ""
auth = HTTPBasicAuth("", "")
headers = {"Content-Type": "application/json"}
debug = False
delete_branch_if_exists = True

script_directory = os.path.dirname(os.path.abspath(__file__))
local_base_dir = os.path.dirname(script_directory)


def print_debug(message: str) -> None:
    if debug:
        print(f"[Debug] {message}")


def delete_branch(branch_name: str) -> None:
    latest_commit_sha = get_latest_commit(branch_name)
    print(f"[Info] Latest commit SHA for '{branch_name}' is '{latest_commit_sha}'.")

    url = f"{base_url}/refs?api-version=7.1"
    data = [
        {
            "name": f"refs/heads/{branch_name}",
            "oldObjectId": latest_commit_sha,
            "newObjectId": "0000000000000000000000000000000000000000",
        }
    ]

    response = requests.post(url, auth=auth, headers=headers, json=data)
    data = response.json()
    count = data.get("count")  # type: ignore[attr-defined]
    success = data.get("value", [{}])[0].get("success")  # type: ignore[attr-defined]

    print_debug(f"Count = {count}, Success = {success}")

    if response.status_code == 200 and count == 1 and success is True:
        print(f"[Info] Branch '{branch_name}' deleted successfully.")
    else:
        raise Exception(f"[Error] Failed to delete branch: {response.status_code} - {response.text}")


def display_usage() -> None:
    print(
        "Usage: python setup_azdo_repository.py "
        "--organization_name <organization_name> "
        "--project_name <project_name> "
        "--repository_name <repository_name> "
        "--branch_name <branch_name> "
        "--base_branch_name <base_branch_name> "
        "--directory_name <directory_name> "
        "--username <username> "
        "--token <token>"
    )


def set_base_url_and_auth(
    organization_name: str, project_name: str, repository_name: str, username: str, token: str
) -> None:
    global base_url, auth
    base_url = f"https://dev.azure.com/{organization_name}/{project_name}/_apis/git/repositories/{repository_name}"
    auth = HTTPBasicAuth(username, token)


def parse_arguments() -> tuple:
    parser = argparse.ArgumentParser()
    parser.add_argument("--organization_name", help="Azure DevOps organization name")
    parser.add_argument("--project_name", help="Azure DevOps project name")
    parser.add_argument("--repository_name", help="Azure DevOps repository name")
    parser.add_argument("--branch_name", help="Git branch name")
    parser.add_argument("--base_branch_name", help="Git base/parent branch name")
    parser.add_argument("--directory_name", help="Fabric directory name")
    parser.add_argument("--username", help="Azure DevOps username")
    parser.add_argument("--token", help="Azure DevOps personal access token")

    args = parser.parse_args()

    organization_name = args.organization_name
    project_name = args.project_name
    repository_name = args.repository_name
    branch_name = args.branch_name
    base_branch_name = args.base_branch_name
    directory_name = args.directory_name
    username = args.username
    token = args.token

    if not all([branch_name, directory_name, organization_name, project_name, repository_name, username, token]):
        display_usage()
        exit(1)

    set_base_url_and_auth(organization_name, project_name, repository_name, username, token)

    return branch_name, base_branch_name, directory_name


def branch_exists(branch_name: str) -> bool:
    url = f"{base_url}/refs?filter=heads/{branch_name}&api-version=7.1"
    response = requests.get(url, auth=auth, headers=headers)

    if response.status_code == 200:
        branches = response.json()
        if branches.get("value"):
            return True
        else:
            return False
    else:
        raise Exception(f"[Error] Failed to fetch branches: {response.status_code} - {response.text}")


def get_default_branch() -> str:
    url = f"{base_url}?api-version=7.1"
    response = requests.get(url, auth=auth, headers=headers)

    if response.status_code == 200:
        repository = response.json()
        return repository["defaultBranch"].replace("refs/heads/", "")
    else:
        raise Exception(f"[Error] Failed to fetch default branch info: {response.status_code} - {response.text}")


def get_latest_commit(branch_name: str) -> str:
    url = f"{base_url}/refs?filter=heads/{branch_name}&api-version=7.1"
    response = requests.get(url, auth=auth, headers=headers)

    if response.status_code == 200:
        commits = response.json()
        if commits.get("value"):
            return commits["value"][0]["objectId"]
        else:
            print(f"[Info] No commits found for branch '{branch_name}'.")
            return "0000000000000000000000000000000000000000"
    else:
        raise Exception(
            f"[Error] Failed to fetch commit for branch '{branch_name}': {response.status_code} - {response.text}"
        )


def create_branch(branch_name: str, base_branch_name: str) -> None:

    if not base_branch_name:
        default_branch = get_default_branch()
    else:
        default_branch = base_branch_name
    print(f"[Info] Default branch: '{default_branch}'")

    latest_commit_sha = get_latest_commit(default_branch)
    print(f"[Info] Creating branch '{branch_name}' from commit '{latest_commit_sha}' on branch '{default_branch}'.")

    url = f"{base_url}/refs?api-version=7.1"
    data = [
        {
            "name": f"refs/heads/{branch_name}",
            "newObjectId": latest_commit_sha,
            "oldObjectId": "0000000000000000000000000000000000000000",
        }
    ]

    response = requests.post(url, auth=auth, headers=headers, json=data)
    data = response.json()
    count = data.get("count")  # type: ignore[attr-defined]
    success = data.get("value", [{}])[0].get("success")  # type: ignore[attr-defined]

    print_debug(f"Count = {count}, Success = {success}")

    if response.status_code == 200 and count == 1 and success is True:
        print(f"[Info] Branch '{branch_name}' created successfully.")
    else:
        raise Exception(f"[Error] Failed to create branch: {response.status_code} - {response.text}")


def add_file(target_path: str, local_file_path: str) -> dict:

    local_file_path = os.path.abspath(os.path.join(local_base_dir, local_file_path))

    with open(local_file_path, "rb") as file:
        content = base64.b64encode(file.read()).decode("utf-8")

    return {
        "changeType": "Add",
        "item": {"path": f"{target_path}"},
        "newContent": {"content": content, "contentType": "base64encoded"},
    }


def commit_push(branch_name: str, commit_message: str, changes: list) -> dict:
    old_object_id = get_latest_commit(branch_name)

    # Prepare commit data with all changes
    commit_data = {
        "refUpdates": [{"name": f"refs/heads/{branch_name}", "oldObjectId": old_object_id}],
        "commits": [{"comment": commit_message, "changes": changes}],
    }

    # Push the commit
    response = requests.post(f"{base_url}/pushes?api-version=7.1", auth=auth, headers=headers, json=commit_data)

    if response.status_code != 201:
        raise Exception(f"[Error] Failed to push commit: {response.status_code} - {response.text}")

    # Return commit response
    return response.json()


def copy_directory(local_file_path: str, target_path: str) -> list:
    changes = []
    for item in os.listdir(os.path.join(local_base_dir, local_file_path)):
        print_debug(f"Processing item: {item}")
        print_debug(f"Local file path: {local_file_path}")
        print_debug(f"Target path: {target_path}")
        # Ignore unwanted files
        if item in [".DS_Store", "Thumbs.db", "desktop.ini"]:
            continue
        if os.path.isfile(os.path.join(local_base_dir, local_file_path, item)):
            changes.append(add_file(f"{target_path}/{item}", f"{local_file_path}/{item}"))
        else:
            changes.extend(copy_directory(f"{local_file_path}/{item}", f"{target_path}/{item}"))
    return changes


def add_setup_cfg() -> dict:
    content = """
[flake8]
exclude = docs
max-line-length = 120
    """.strip()

    return {
        "changeType": "Add",
        "item": {"path": "setup.cfg"},
        "newContent": {"content": content, "contentType": "rawtext"},
    }


# Main function to orchestrate the process
def main() -> None:
    branch_name, base_branch_name, fabric_directory_name = parse_arguments()

    # Creating a new branch if it doesn't exist
    if branch_exists(branch_name):
        print(f"[Info] Branch '{branch_name}' already exists.")
        if delete_branch_if_exists:
            print("[Warning] Variable 'delete_branch_if_exists' set to 'True', deleting the branch.")
            delete_branch(branch_name)
            print(f"[Info] Creating new branch '{branch_name}'.")
            create_branch(branch_name, base_branch_name)
        else:
            print("[Info] Variable 'delete_branch_if_exists' set to `False`, skipping branch deletion.")
    else:
        create_branch(branch_name, base_branch_name)

    if not base_branch_name:
        # config
        print("[Info] Copying config files to Azure repo.")
        changes = copy_directory("config", "config")
        response = commit_push(branch_name, commit_message="Add config files", changes=changes)
        print_debug(f"[Info] Commit response: {response}")

        # data
        print("[Info] Copying data files to Azure repo.")
        changes = copy_directory("data", "data")
        response = commit_push(branch_name, commit_message="Add seed data files", changes=changes)
        print_debug(f"[Info] Commit response: {response}")

        # devops
        print("[Info] Copying devops files to Azure repo.")
        changes = copy_directory("devops", "devops")
        response = commit_push(branch_name, commit_message="Add ci/cd files", changes=changes)
        print_debug(f"[Info] Commit response: {response}")

        # fabric
        print("[Info] Copying fabric files to Azure repo.")
        changes = copy_directory("fabric", fabric_directory_name)
        changes.append(
            {
                "changeType": "Add",
                "item": {"path": f"{fabric_directory_name}/workspace/README.md"},
                "newContent": {"content": "", "contentType": "rawtext"},
            }
        )  # Adding an empty file to create the fabric workspace folder
        response = commit_push(branch_name, commit_message="Add fabric files", changes=changes)
        print_debug(f"[Info] Commit response: {response}")

        # libraries
        print("[Info] Copying library files to Azure repo.")
        changes = copy_directory("libraries", "libraries")
        response = commit_push(branch_name, commit_message="Add library files", changes=changes)
        print_debug(f"[Info] Commit response: {response}")

        # setup.cfg
        print("[Info] Adding setup.cfg file to Azure repo.")
        changes = [add_setup_cfg()]
        response = commit_push(branch_name, commit_message="Add setup.cfg file", changes=changes)
        print_debug(f"[Info] Commit response: {response}")
    else:
        print(f"[Info] As branch '{branch_name}' is based on newly created branch '{base_branch_name}', skipping copy.")


if __name__ == "__main__":
    main()
