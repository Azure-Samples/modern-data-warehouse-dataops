import os

import utils
import yaml
from dotenv import load_dotenv

load_dotenv()

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Access Token
azure_management_bearer_token = os.environ.get("AZURE_MANAGEMENT_BEARER_TOKEN")
azure_storage_bearer_token = os.environ.get("AZURE_STORAGE_BEARER_TOKEN")
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")

# Azure Resources
subscription_id = os.environ.get("SUBSCRIPTION_ID")
resource_group_name = os.environ.get("RESOURCE_GROUP_NAME")
fabric_workspace_group_admin = os.environ.get("FABRIC_WORKSPACE_GROUP_ADMIN")
storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
storage_account_role_definition_id = os.environ.get("STORAGE_ACCOUNT_ROLE_DEFINITION_ID")
storage_container_name = os.environ.get("STORAGE_CONTAINER_NAME")

# Azure Devops
organization_name = os.environ.get("ORGANIZATIONAL_NAME")
project_name = os.environ.get("PROJECT_NAME")
repo_name = os.environ.get("REPO_NAME")
fabric_workspace_directory = os.environ.get("FABRIC_WORKSPACE_DIRECTORY")
feature_branch = os.environ.get("FEATURE_BRANCH")
commit_hash = os.environ.get("COMMIT_HASH")

# Fabric
fabric_capacity_name = os.environ.get("FABRIC_CAPACITY_NAME")
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_environment_name = os.environ.get("FABRIC_ENVIRONMENT_NAME")
fabric_custom_pool_name = os.environ.get("FABRIC_CUSTOM_POOL_NAME")
fabric_connection_name = os.environ.get("FABRIC_CONNECTION_NAME")
fabric_lakehouse_name = os.environ.get("FABRIC_LAKEHOUSE_NAME")
fabric_shortcut_name = os.environ.get("FABRIC_SHORTCUT_NAME")

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
azure_management_headers = {
    "Authorization": f"Bearer {azure_management_bearer_token}",
    "Content-Type": "application/json",
}
azure_storage_headers = {"Authorization": f"Bearer {azure_storage_bearer_token}", "x-ms-version": "2021-02-12"}
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
    if not azure_management_bearer_token:
        error_list.append("AZURE_MANAGEMENT_BEARER_TOKEN")
    if not azure_storage_bearer_token:
        error_list.append("AZURE_STORAGE_BEARER_TOKEN")
    if not fabric_bearer_token:
        error_list.append("FABRIC_BEARER_TOKEN")

    # Azure Resources
    if not subscription_id:
        error_list.append("SUBSCRIPTION_ID")
    if not resource_group_name:
        error_list.append("RESOURCE_GROUP_NAME")
    if not fabric_workspace_group_admin:
        error_list.append("FABRIC_WORKSPACE_GROUP_ADMIN")
    if not storage_account_name:
        error_list.append("STORAGE_ACCOUNT_NAME")
    if not storage_account_role_definition_id:
        error_list.append("STORAGE_ACCOUNT_ROLE_DEFINITION_ID")
    if not storage_container_name:
        error_list.append("STORAGE_CONTAINER_NAME")

    # Azure Devops
    if not organization_name:
        error_list.append("ORGANIZATIONAL_NAME")
    if not project_name:
        error_list.append("PROJECT_NAME")
    if not repo_name:
        error_list.append("REPO_NAME")
    if not fabric_workspace_directory:
        error_list.append("FABRIC_WORKSPACE_DIRECTORY")
    if not feature_branch:
        error_list.append("FEATURE_BRANCH")
    if not commit_hash:
        error_list.append("COMMIT_HASH")

    # Fabric
    if not fabric_capacity_name:
        error_list.append("FABRIC_CAPACITY_NAME")
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_environment_name:
        error_list.append("FABRIC_ENVIRONMENT_NAME")
    if not fabric_custom_pool_name:
        error_list.append("FABRIC_CUSTOM_POOL_NAME")
    if not fabric_connection_name:
        error_list.append("FABRIC_CONNECTION_NAME")
    if not fabric_lakehouse_name:
        error_list.append("FABRIC_LAKEHOUSE_NAME")
    if not fabric_shortcut_name:
        error_list.append("FABRIC_SHORTCUT_NAME")

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    capacity_id = utils.get_capacity_id(fabric_headers, fabric_capacity_name)
    if capacity_id:
        print(f"[Info] Capacity details: '{fabric_capacity_name}' ({capacity_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve capacity ID for '{fabric_capacity_name}'")

    print("[Info] ############ Workspace Creation ############")

    workspace_id = utils.get_workspace_id(fabric_headers, fabric_workspace_name)
    if workspace_id:
        print(f"[Info] Workspace '{fabric_workspace_name}' already exists.")
    else:
        print(f"[Info] Workspace '{fabric_workspace_name}' doesn't exist. Creating workspace.")

        workspace_id = utils.create_workspace(fabric_headers, fabric_workspace_name, capacity_id)
        utils.add_workspace_role_assignment(
            fabric_headers, workspace_id, fabric_workspace_group_admin, "Group", "Admin"
        )
        utils.provision_workspace_identity(fabric_headers, workspace_id)

    print(f"[Info] Workspace details: '{fabric_workspace_name}' ({workspace_id})")

    print("[Info] ############ Syncing workspace to git ############")

    git_status = utils.get_workspace_git_status(fabric_headers, workspace_id)
    if not git_status:
        print("[Info] Workspace is not connected to git. Connecting to git.")
        # Azure DevOps details
        azure_devops_details = {
            "gitProviderType": "AzureDevOps",
            "organizationName": organization_name,
            "projectName": project_name,
            "repositoryName": repo_name,
            "branchName": feature_branch,
            "directoryName": fabric_workspace_directory,
        }
        utils.connect_workspace_to_git(fabric_headers, workspace_id, azure_devops_details)
        utils.initialize_connection(fabric_headers, workspace_id)
        workspace_head = None
    else:
        workspace_head = git_status["workspaceHead"]

    utils.update_workspace_from_git(fabric_headers, workspace_id, commit_hash, workspace_head)

    print("[Info] ############ Creating spark custom pool ############")

    environment_id = utils.get_environment_id(fabric_headers, workspace_id, fabric_environment_name)

    if environment_id:
        print(f"[Info] Environment details: '{fabric_environment_name}' ({environment_id})")
    else:
        print(f"[Error] Failed to retrieve environment id for '{fabric_environment_name}'")
        exit(1)

    # Spark compute settings
    env_files_dir = os.path.join(os.path.dirname(__file__), "../../fabric/fabric_environment")
    custom_pool_id = utils.get_custom_pool_id(fabric_headers, workspace_id, fabric_custom_pool_name)

    if custom_pool_id:
        print(f"[Info] Custom pool '{fabric_custom_pool_name}' already exists.")
    else:
        print(f"[Info] Custom pool '{fabric_custom_pool_name}' doesn't exist. Creating custom pool.")

        yaml_file_path = os.path.join(env_files_dir, "spark_pool_settings.yml")
        with open(yaml_file_path, "r") as file:
            custom_pool_details = yaml.safe_load(file)
        custom_pool_details["name"] = fabric_custom_pool_name

        utils.create_workspace_custom_pool(fabric_headers, workspace_id, custom_pool_details)
        utils.update_spark_pool(fabric_headers, workspace_id, environment_id, fabric_custom_pool_name)

    print(f"[Info] Custom pool details: '{fabric_custom_pool_name}' ({custom_pool_id})")

    print("[Info] ############ Creating ADLS shortcut ############")

    # Creating storage container
    storage_container = utils.get_storage_container(azure_storage_headers, storage_account_name, storage_container_name)
    if storage_container:
        print(f"[Info] Storage container '{storage_container_name}' already exists. Response: {storage_container}")
    else:
        print(f"[Info] Storage container '{storage_container_name}' doesn't exist. Creating storage container.")
        utils.create_storage_container(azure_storage_headers, storage_account_name, storage_container_name)

    # Adding role assignment to workspace
    workspace = utils.get_workspace(fabric_headers, workspace_id)
    if not workspace:
        print(f"[Error] Failed to retrieve workspace details for '{workspace_id}'")
        exit(1)

    workspace_identity = workspace["workspaceIdentity"]
    scope = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/"
        f"providers/Microsoft.Storage/storageAccounts/{storage_account_name}"
    )
    role_definition_id = (
        f"/subscriptions/{subscription_id}/providers/Microsoft.Authorization/"
        f"roleDefinitions/{storage_account_role_definition_id}"
    )

    if utils.get_storage_role_assignments(azure_management_headers, scope, workspace_identity["servicePrincipalId"]):
        print("[Info] Storage role assignment already exists.")
    else:
        utils.add_storage_account_role_assignments(
            azure_management_headers, workspace_identity["servicePrincipalId"], scope, role_definition_id
        )

    # Creating connection
    storage_account_url = f"https://{storage_account_name}.dfs.core.windows.net"

    connection_id = utils.get_connection_id(fabric_headers, fabric_connection_name)
    if connection_id:
        print(f"[Info] Connection '{fabric_connection_name}' already exists.")
    else:
        print(f"[Info] Connection '{fabric_connection_name}' doesn't exist. Creating connection.")
        connection_id = utils.create_adls_cloud_connection(
            fabric_headers, fabric_connection_name, storage_account_url, storage_container_name
        )
        utils.add_connection_role_assignment(
            fabric_headers, connection_id, fabric_workspace_group_admin, "Group", "Owner"
        )

    # Creating shortcut
    lakehouse_id = utils.get_item_id(fabric_headers, workspace_id, "Lakehouse", fabric_lakehouse_name)
    if lakehouse_id:
        print(f"[Info] Lakehouse details: '{fabric_lakehouse_name}' ({lakehouse_id})")

        if utils.get_shortcut(fabric_headers, workspace_id, lakehouse_id, "Files", fabric_shortcut_name):
            print(f"[Info] Shortcut '{fabric_shortcut_name}' already exists.")
        else:
            print(f"[Info] Shortcut '{fabric_shortcut_name}' doesn't exist. Creating shortcut.")
            target = {
                "adlsGen2": {
                    "connectionId": connection_id,
                    "location": storage_account_url,
                    "subpath": storage_container_name,
                }
            }
            utils.create_shortcut(fabric_headers, workspace_id, lakehouse_id, "Files", fabric_shortcut_name, target)
    else:
        print(f"[Error] Failed to retrieve lakehouse id for '{fabric_lakehouse_name}'")
        exit(1)
