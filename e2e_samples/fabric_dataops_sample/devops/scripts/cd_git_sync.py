import os

import utils

# from dotenv import load_dotenv
# load_dotenv(
#     "/home/naga/dev/ext_gitrepos/naga_mde_feat/modern-data-warehouse-dataops/_scratch/naga_cd.env", override=True
# )

# get bearer tokens and headers
(
    azure_management_headers,
    azure_storage_headers,
    fabric_headers,
    azure_management_bearer_token,
    azure_storage_bearer_token,
    fabric_bearer_token,
) = utils.get_bearer_tokens_and_headers()


# Fabric
fabric_capacity_name = os.environ.get("FABRIC_CAPACITY_NAME")
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")


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
        error_list.append("azure_management_bearer_token")
    if not azure_storage_bearer_token:
        error_list.append("azure_storage_bearer_token")
    if not fabric_bearer_token:
        error_list.append("fabric_bearer_token")

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    capacity_id = utils.get_capacity_id(headers=fabric_headers, capacity_name=fabric_capacity_name)
    if capacity_id:
        print(f"[Info] Capacity details: '{fabric_capacity_name}' ({capacity_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve capacity ID for '{fabric_capacity_name}'")

    print("[Info] ############ Workspace Related Tasks ############")

    workspace_id = utils.get_workspace_id(headers=fabric_headers, workspace_name=fabric_workspace_name)
    if workspace_id:
        print(f"[Info] Workspace '{fabric_workspace_name}' already exists.")
        print(f"[Info] Workspace details: '{fabric_workspace_name}' ({workspace_id})")
    else:
        raise Exception(f"[Error] Workspace '{fabric_workspace_name}' doesn't exist.")

    print("[Info] ------------------ Accept Git changes and update the workspace ------------------")

    git_status = utils.get_workspace_git_status(fabric_headers, workspace_id)
    if not git_status:
        print("[Error] Workspace is not connected to git. Please check the workspace.")
    else:
        workspace_head = git_status.get("workspaceHead")
        remote_commit_hash = git_status.get("remoteCommitHash")
        print(f"[Info] workspace_head: {workspace_head}")
        print(f"[Info] remote_commit_hash: {remote_commit_hash}")

        if workspace_head != remote_commit_hash:
            print("[Info] Accept Git changes and update the workspace")
            utils.update_workspace_from_git(
                headers=fabric_headers,
                workspace_id=workspace_id,
                commit_hash=remote_commit_hash,
                workspace_head=workspace_head,
            )
        else:
            print("[Info] No new commit to update the workspace")
    print("[Info] ------------------ Git Sync Completed ------------------")
    print("[Info] ############ Workspace Related Tasks Completed ############")
