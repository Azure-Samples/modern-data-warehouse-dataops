import logging
import os

import utils

# Configure logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Get bearer tokens and headers
(
    azure_management_headers,
    azure_storage_headers,
    fabric_headers,
    azure_management_bearer_token,
    azure_storage_bearer_token,
    fabric_bearer_token,
) = utils.get_bearer_tokens_and_headers()

# Fabric environment variables
fabric_capacity_name = os.environ.get("FABRIC_CAPACITY_NAME")
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")


class ValidationError(Exception):
    """Custom exception for validation errors."""

    def __init__(self, message: str) -> None:
        self.message = message
        logging.error(self.message)
        exit(1)


def main() -> None:
    """Main function to orchestrate the git sync process."""
    validate_env()
    logging.info("############ Workspace Related Tasks ############")
    _ = get_capacity_details()
    workspace_id = get_workspace_details()
    logging.info("------------------ Accept Git changes and update the workspace ------------------")
    sync_git_changes(workspace_id)
    logging.info("------------------ Git Sync Completed ------------------")
    logging.info("############ Workspace Related Tasks Completed ############")


def validate_env() -> None:
    """Validate the required environment variables and tokens."""
    required_env_vars = [
        "FABRIC_CAPACITY_NAME",
        "FABRIC_WORKSPACE_NAME",
    ]

    error_list = [var for var in required_env_vars if not os.environ.get(var)]

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


def get_capacity_details() -> str:
    """Retrieve and log the capacity details."""
    capacity_id = utils.get_capacity_id(headers=fabric_headers, capacity_name=fabric_capacity_name)
    if capacity_id:
        logging.info(f"Capacity details: '{fabric_capacity_name}' ({capacity_id})")
    else:
        raise Exception(f"Failed to retrieve capacity ID for '{fabric_capacity_name}'")
    return capacity_id


def get_workspace_details() -> str:
    """Retrieve and log the workspace details."""
    workspace_id = utils.get_workspace_id(headers=fabric_headers, workspace_name=fabric_workspace_name)
    if workspace_id:
        logging.info(f"Workspace '{fabric_workspace_name}' already exists.")
        logging.info(f"Workspace details: '{fabric_workspace_name}' ({workspace_id})")
    else:
        raise Exception(f"Workspace '{fabric_workspace_name}' doesn't exist.")
    return workspace_id


def sync_git_changes(workspace_id: str) -> None:
    """Sync git changes and update the workspace."""
    git_status = utils.get_workspace_git_status(fabric_headers, workspace_id)
    if not git_status:
        logging.error("Workspace is not connected to git. Please check the workspace.")
    else:
        workspace_head = git_status.get("workspaceHead")
        remote_commit_hash = git_status.get("remoteCommitHash")
        logging.info(f"workspace_head: {workspace_head}")
        logging.info(f"remote_commit_hash: {remote_commit_hash}")

        if workspace_head != remote_commit_hash:
            logging.info("Accept Git changes and update the workspace")
            utils.update_workspace_from_git(
                headers=fabric_headers,
                workspace_id=workspace_id,
                commit_hash=remote_commit_hash,
                workspace_head=workspace_head,
            )
        else:
            logging.info("No new commit to update the workspace")


if __name__ == "__main__":
    main()
