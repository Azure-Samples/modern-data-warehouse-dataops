import os
import time

import utils
import yaml

# from dotenv import load_dotenv
# load_dotenv(
#     "/home/naga/dev/ext_gitrepos/naga_mde_feat/modern-data-warehouse-dataops/_scratch/naga_cd.env", override=True
# )


update_spark_compute_settings = True
update_public_libraries = True
update_custom_libraries = True

# get bearer tokens and headers
(
    azure_management_headers,
    azure_storage_headers,
    fabric_headers,
    azure_management_bearer_token,
    azure_storage_bearer_token,
    fabric_bearer_token,
) = utils.get_bearer_tokens_and_headers()

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
ci_artifacts_path = os.environ.get("CI_ARTIFACTS_PATH")

# Azure Resources
storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
storage_container_name = os.environ.get("STORAGE_CONTAINER_NAME")


# Fabric
fabric_capacity_name = os.environ.get("FABRIC_CAPACITY_NAME")
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_environment_name = os.environ.get("FABRIC_ENVIRONMENT_NAME")
fabric_custom_pool_name = os.environ.get("FABRIC_CUSTOM_POOL_NAME")
fabric_connection_name = os.environ.get("FABRIC_ADLS_CONNECTION_NAME")
fabric_lakehouse_name = os.environ.get("FABRIC_LAKEHOUSE_NAME")
fabric_shortcut_name = os.environ.get("FABRIC_ADLS_SHORTCUT_NAME")


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

    # Azure Resources
    if not storage_account_name:
        error_list.append("STORAGE_ACCOUNT_NAME")
    if not storage_container_name:
        error_list.append("STORAGE_CONTAINER_NAME")

    # Fabric
    if not fabric_capacity_name:
        error_list.append("FABRIC_CAPACITY_NAME")
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_environment_name:
        error_list.append("FABRIC_ENVIRONMENT_NAME")
    if not fabric_custom_pool_name:
        error_list.append("FABRIC_CUSTOM_POOL_NAME")

    if not ci_artifacts_path:
        error_list.append("CI_ARTIFACTS_PATH")

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

    # Creating connection
    storage_account_url = f"https://{storage_account_name}.dfs.core.windows.net"

    connection_id = utils.get_connection_id(fabric_headers, fabric_connection_name)
    if connection_id:
        print(f"[Info] Connection '{fabric_connection_name}' already exists.")
    else:
        raise Exception(f"[Error] Failed to retrieve connection id for '{fabric_connection_name}'")

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
            print(target)
            # Wait for the storage container to be available
            # time.sleep(120)
            utils.create_shortcut(fabric_headers, workspace_id, lakehouse_id, "Files", fabric_shortcut_name, target)
    else:
        raise Exception(f"[Error] Failed to retrieve lakehouse id for '{fabric_lakehouse_name}'")

    print("[Info] ############ Environment Related Tasks ############")

    environment_id = utils.get_environment_id(fabric_headers, workspace_id, fabric_environment_name)

    if environment_id:
        print(f"[Info] Environment details: '{fabric_environment_name}' ({environment_id})")
    else:
        raise Exception(f"[Error] Failed to retrieve environment id for '{fabric_environment_name}'")

    print("[Info] ------------------ Custom Pool Related Tasks ------------------")
    custom_pool_id = utils.get_custom_pool_id(
        headers=fabric_headers, workspace_id=workspace_id, custom_pool_name=fabric_custom_pool_name
    )
    if custom_pool_id:
        print(f"[Info] Custom pool '{fabric_custom_pool_name}' already exists.")
    else:
        raise Exception(f"[Error] Failed to retrieve custom pool id for '{fabric_custom_pool_name}'")

    current_custom_pool = utils.get_custom_pool_by_name(
        headers=fabric_headers, workspace_id=workspace_id, custom_pool_name=fabric_custom_pool_name
    )

    if update_spark_compute_settings:
        env_files_dir = os.path.join(ci_artifacts_path, "./fabric_env")
        yaml_file_path = os.path.join(env_files_dir, "spark_pool_settings.yml")
        with open(yaml_file_path, "r") as file:
            latest_custom_pool = yaml.safe_load(file)
        if latest_custom_pool is not None and current_custom_pool is not None:
            latest_custom_pool["id"] = current_custom_pool["id"]
            latest_custom_pool["name"] = fabric_custom_pool_name
            latest_custom_pool["type"] = "Workspace"

            # If the custom pool details are different, update the custom pool
            if current_custom_pool != latest_custom_pool:
                print(f"[Info] Current custom pool details: {current_custom_pool}")
                print(f"[Info] Latest custom pool details: {latest_custom_pool}")
                print(f"[Info] Updating custom pool '{fabric_custom_pool_name}' details.")
                utils.update_workspace_custom_pool(
                    fabric_headers, workspace_id, current_custom_pool["id"], latest_custom_pool
                )

            else:
                print("[Info] No changes in the custom pool")

    print("[Info] ------------------ Public and Custom Library Related Tasks ------------------")

    if update_public_libraries:
        public_libs_dir = os.path.join(ci_artifacts_path, "./fabric_env/")
        list_of_files = ["environment.yml"]
        for file_name in os.listdir(public_libs_dir):
            if file_name in list_of_files:
                utils.upload_staging_library(
                    headers=fabric_headers,
                    workspace_id=workspace_id,
                    environment_id=environment_id,
                    file_path=public_libs_dir,
                    file_name=file_name,
                    content_type="multipart/form-data",
                )

    if update_custom_libraries:
        library_files_dir = os.path.join(ci_artifacts_path, "./fabric_env/custom_libraries")
        list_of_files = [
            "ddo_transform_transform.py",
            "ddo_transform_standardize.py",
            "otel_monitor_invoker.py",
        ]
        for file_name in os.listdir(library_files_dir):
            if file_name in list_of_files:
                utils.upload_staging_library(
                    headers=fabric_headers,
                    workspace_id=workspace_id,
                    environment_id=environment_id,
                    file_path=library_files_dir,
                    file_name=file_name,
                    content_type="application/x-python-wheel",
                )

    print("[Info] ------------------ Publish environment if there are staged changes ------------------")
    staging_spark_compute_settings = utils.get_spark_compute_settings(
        headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id, status="staging"
    )
    staging_libraries = utils.get_libraries(
        headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id, status="staging"
    )

    published_spark_compute_settings = utils.get_spark_compute_settings(
        headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id, status="published"
    )
    published_libraries = utils.get_libraries(
        headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id, status="published"
    )

    print(f"[Info] staging_spark_compute_settings = {staging_spark_compute_settings}")
    print(f"[Info] published_spark_compute_settings = {published_spark_compute_settings}")

    print(f"[Info] staging_libraries = {staging_libraries}")
    print(f"[Info] published_libraries = {published_libraries}")

    if (staging_spark_compute_settings != published_spark_compute_settings) or (staging_libraries is not None):
        print("[Info] There are changes in spark compute settings or libraries. Publishing the environment.")
        print("[Info] ---------------------- Publishing environment ----------------------")
        utils.publish_environment(headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id)

        # Polling environment status
        while utils.get_publish_environment_status(fabric_headers, workspace_id, environment_id).lower() in [
            "running",
            "waiting",
        ]:
            print("[Info] Environment publishing is in progress.")
            time.sleep(60)
        print("[Info] Environment publishing completed.")
    else:
        print("[Info] There are no changes in spark compute settings or libraries. Publishing the environment.")
