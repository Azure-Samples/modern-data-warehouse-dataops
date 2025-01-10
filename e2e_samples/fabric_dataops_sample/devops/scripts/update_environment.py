import os
import time

import utils
import yaml
from dotenv import load_dotenv

load_dotenv()

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Access Token
fabric_bearer_token = os.environ.get("FABRIC_BEARER_TOKEN")

# Fabric
fabric_workspace_name = os.environ.get("FABRIC_WORKSPACE_NAME")
fabric_environment_name = os.environ.get("FABRIC_ENVIRONMENT_NAME")
fabric_custom_pool_name = os.environ.get("FABRIC_CUSTOM_POOL_NAME")

# Process Flags
update_public_libraries = os.environ.get("UPDATE_PUBLIC_LIBRARIES", "False").lower() == "true"
update_custom_libraries = os.environ.get("UPDATE_CUSTOM_LIBRARIES", "False").lower() == "true"

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
fabric_api_endpoint = "https://api.fabric.microsoft.com/v1"
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
    if not fabric_bearer_token:
        error_list.append("FABRIC_BEARER_TOKEN")

    # Fabric
    if not fabric_workspace_name:
        error_list.append("FABRIC_WORKSPACE_NAME")
    if not fabric_environment_name:
        error_list.append("FABRIC_ENVIRONMENT_NAME")
    if not fabric_custom_pool_name:
        error_list.append("FABRIC_CUSTOM_POOL_NAME")

    if error_list:
        raise ValidationError("The following mandatory environment variables are not set: " + ", ".join(error_list))


if __name__ == "__main__":
    # Validate environment variables
    validate_env()

    workspace_id = utils.get_workspace_id(fabric_headers, fabric_workspace_name)
    if not workspace_id:
        raise Exception(f"[Error] Workspace '{fabric_workspace_name}' not found.")

    environment_id = utils.get_environment_id(fabric_headers, workspace_id, fabric_environment_name)
    if not environment_id:
        raise Exception(f"[Error] Environment '{fabric_environment_name}' not found.")

    # -----------------------------------------------------------------------------
    # Updating custom pool
    # -----------------------------------------------------------------------------
    current_custom_pool = utils.get_custom_pool_by_name(fabric_headers, workspace_id, fabric_custom_pool_name)
    if not current_custom_pool:
        raise Exception(f"[Error] Custom pool '{fabric_custom_pool_name}' not found.")

    # Get latest custom pool details from the environment file
    env_files_dir = os.path.join(os.path.dirname(__file__), "../../fabric/fabric_environment")
    yaml_file_path = os.path.join(env_files_dir, "spark_pool_settings.yml")
    with open(yaml_file_path, "r") as file:
        latest_custom_pool = yaml.safe_load(file)
    latest_custom_pool["id"] = current_custom_pool["id"]
    latest_custom_pool["name"] = fabric_custom_pool_name

    # If the custom pool details are different, update the custom pool
    if current_custom_pool != latest_custom_pool:
        print(f"[Info] Current custom pool details: {current_custom_pool}")
        print(f"[Info] Latest custom pool details: {latest_custom_pool}")
        print(f"[Info] Updating custom pool '{fabric_custom_pool_name}' details.")
        utils.update_workspace_custom_pool(fabric_headers, workspace_id, current_custom_pool["id"], latest_custom_pool)

    # -----------------------------------------------------------------------------
    # Updating public libraries
    # -----------------------------------------------------------------------------
    if update_public_libraries:
        utils.upload_staging_library(
            fabric_headers,
            workspace_id,
            environment_id,
            env_files_dir,
            "environment.yml",
            "multipart/form-data",
        )

    # -----------------------------------------------------------------------------
    # Updating custom libraries
    # -----------------------------------------------------------------------------
    if update_custom_libraries:
        library_files_dir = os.path.join(os.path.dirname(__file__), "../../libraries/src")

        utils.upload_staging_library(
            fabric_headers,
            workspace_id,
            environment_id,
            library_files_dir,
            "ddo_transform_standardize.py",
            "application/x-python-wheel",
        )

        utils.upload_staging_library(
            fabric_headers,
            workspace_id,
            environment_id,
            library_files_dir,
            "ddo_transform_transform.py",
            "application/x-python-wheel",
        )

        utils.upload_staging_library(
            fabric_headers,
            workspace_id,
            environment_id,
            library_files_dir,
            "otel_monitor_invoker.py",
            "application/x-python-wheel",
        )

    # -----------------------------------------------------------------------------
    # Publishing environment
    # -----------------------------------------------------------------------------
    staging_spark_compute_settings = utils.get_spark_compute_settings(
        fabric_headers, workspace_id, environment_id, "staging"
    )
    staging_libraries = utils.get_libraries(fabric_headers, workspace_id, environment_id, "staging")

    published_spark_compute_settings = utils.get_spark_compute_settings(
        fabric_headers, workspace_id, environment_id, "published"
    )
    published_libraries = utils.get_libraries(fabric_headers, workspace_id, environment_id, "published")

    if (staging_spark_compute_settings != published_spark_compute_settings) or (
        staging_libraries != published_libraries
    ):
        print("[Info] ############ Publishing environment ############")
        utils.publish_environment(fabric_headers, workspace_id, environment_id)

        # Polling environment status
        while utils.get_publish_environment_status(fabric_headers, workspace_id, environment_id) == "running":
            print("[Info] Environment publishing is in progress.")
            time.sleep(60)
        print("[Info] Environment publishing completed.")
