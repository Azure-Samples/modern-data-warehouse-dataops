import logging
import os
import time

import utils
import yaml

# Configure logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

update_spark_compute_settings = True
update_public_libraries = True
update_custom_libraries = True

# Get bearer tokens and headers
(
    azure_management_headers,
    azure_storage_headers,
    fabric_headers,
    azure_management_bearer_token,
    azure_storage_bearer_token,
    fabric_bearer_token,
) = utils.get_bearer_tokens_and_headers()

# Environment Variables
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


class ValidationError(Exception):
    """Custom exception for validation errors."""

    def __init__(self, message: str) -> None:
        self.message = message
        logging.error(self.message)
        exit(1)


def main() -> None:
    """Main function to orchestrate the workspace item sync process."""
    validate_env()
    _ = get_capacity_details()
    logging.info("############ Workspace Related Tasks ############")
    workspace_id = get_workspace_details()
    connection_id = get_connection_details()
    create_shortcut(workspace_id, connection_id)
    logging.info("############ Environment Related Tasks ############")
    environment_id = utils.get_environment_id(fabric_headers, workspace_id, fabric_environment_name)
    if environment_id:
        logging.info(f"Environment details: '{fabric_environment_name}' ({environment_id})")
    else:
        raise Exception(f"Failed to retrieve environment id for '{fabric_environment_name}'")
    logging.info("------------------ Custom Pool Related Tasks ------------------")
    update_custom_pool(workspace_id)
    logging.info("------------------ Public and Custom Library Related Tasks ------------------")
    update_libraries(workspace_id, environment_id)
    logging.info("------------------ Publish environment if there are staged changes ------------------")
    publish_environment_if_needed(workspace_id, environment_id)
    logging.info("############ Workspace Related Tasks Completed ############")


def validate_env() -> None:
    """Validate the required environment variables and tokens."""
    required_env_vars = [
        "STORAGE_ACCOUNT_NAME",
        "STORAGE_CONTAINER_NAME",
        "FABRIC_CAPACITY_NAME",
        "FABRIC_WORKSPACE_NAME",
        "FABRIC_ENVIRONMENT_NAME",
        "FABRIC_CUSTOM_POOL_NAME",
        "FABRIC_ADLS_CONNECTION_NAME",
        "FABRIC_LAKEHOUSE_NAME",
        "FABRIC_ADLS_SHORTCUT_NAME",
        "CI_ARTIFACTS_PATH",
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


def get_connection_details() -> str:
    """Create and log the connection details."""
    connection_id = utils.get_connection_id(fabric_headers, fabric_connection_name)
    if connection_id:
        logging.info(f"Connection '{fabric_connection_name}' already exists.")
    else:
        raise Exception(f"Failed to retrieve connection id for '{fabric_connection_name}'")
    return connection_id


def create_shortcut(workspace_id: str, connection_id: str) -> None:
    """Create and log the shortcut details."""
    storage_account_url = f"https://{storage_account_name}.dfs.core.windows.net"
    lakehouse_id = utils.get_item_id(fabric_headers, workspace_id, "Lakehouse", fabric_lakehouse_name)
    if lakehouse_id:
        logging.info(f"Lakehouse details: '{fabric_lakehouse_name}' ({lakehouse_id})")

        if utils.get_shortcut(fabric_headers, workspace_id, lakehouse_id, "Files", fabric_shortcut_name):
            logging.info(f"Shortcut '{fabric_shortcut_name}' already exists.")
        else:
            logging.info(f"Shortcut '{fabric_shortcut_name}' doesn't exist. Creating shortcut.")
            target = {
                "adlsGen2": {
                    "connectionId": connection_id,
                    "location": storage_account_url,
                    "subpath": storage_container_name,
                }
            }
            logging.info(target)
            utils.create_shortcut(fabric_headers, workspace_id, lakehouse_id, "Files", fabric_shortcut_name, target)
    else:
        raise Exception(f"Failed to retrieve lakehouse id for '{fabric_lakehouse_name}'")


def update_custom_pool(workspace_id: str) -> None:
    """Update the custom pool if necessary."""
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
                logging.info(f"Current custom pool details: {current_custom_pool}")
                logging.info(f"Latest custom pool details: {latest_custom_pool}")
                logging.info(f"Updating custom pool '{fabric_custom_pool_name}' details.")
                utils.update_workspace_custom_pool(
                    fabric_headers, workspace_id, current_custom_pool["id"], latest_custom_pool
                )
            else:
                logging.info("No changes in the custom pool")


def update_libraries(workspace_id: str, environment_id: str) -> None:
    """Update public and custom libraries."""
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


def publish_environment_if_needed(workspace_id: str, environment_id: str) -> None:
    """Publish the environment if there are staged changes."""
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

    logging.info(f"staging_spark_compute_settings = {staging_spark_compute_settings}")
    logging.info(f"published_spark_compute_settings = {published_spark_compute_settings}")

    logging.info(f"staging_libraries = {staging_libraries}")
    logging.info(f"published_libraries = {published_libraries}")

    if (staging_spark_compute_settings != published_spark_compute_settings) or (staging_libraries is not None):
        logging.info("There are changes in spark compute settings or libraries. Publishing the environment.")
        logging.info("---------------------- Publishing environment ----------------------")
        utils.publish_environment(headers=fabric_headers, workspace_id=workspace_id, environment_id=environment_id)

        # Polling environment status
        while utils.get_publish_environment_status(fabric_headers, workspace_id, environment_id).lower() in [
            "running",
            "waiting",
        ]:
            logging.info("Environment publishing is in progress.")
            time.sleep(60)
        logging.info("Environment publishing completed.")
    else:
        logging.info("There are no changes in spark compute settings or libraries. Publishing the environment.")


if __name__ == "__main__":
    main()
