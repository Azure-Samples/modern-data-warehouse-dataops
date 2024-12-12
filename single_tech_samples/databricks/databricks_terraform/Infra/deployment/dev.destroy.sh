#!/bin/bash

load_env_variables() {
    if [[ -f .env ]]; then
        echo "Loading environment variables from .env file"
        source .env
    else
        echo ".env file not found!"
        exit 1
    fi
}


check_resource_group_name() {
    if [[ -z "${resource_group_name}" ]]; then
        echo "Resource group name is not defined in .env file!"
        exit 1
    fi
}


check_resource_group() {
    az group exists --name "$1"
}


delete_resource_group() {
    echo "Checking if Azure resource group exists: ${resource_group_name}"

    resource_group_exists=$(check_resource_group "${resource_group_name}")
    
    if [[ "${resource_group_exists}" == "true" ]]; then
        echo "Deleting Azure resource group: ${resource_group_name}"
        if ! az group delete --name "${resource_group_name}" --yes --no-wait; then
            echo "Failed to delete resource group: ${resource_group_name}"
        fi
        wait_for_deletion
    else
        echo "Resource group ${resource_group_name} does not exist. Skipping deletion."
    fi
}


wait_for_deletion() {
    echo "Waiting for resource group deletion to complete..."
    start_time=$(date +%s)

    while [[ "$(check_resource_group "${resource_group_name}")" == "true" ]]; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        echo "Resource group ${resource_group_name} still exists. Time elapsed: ${elapsed_time} seconds. Checking again in 10 seconds..."
        sleep 10
    done

    total_time=$(( $(date +%s) - start_time ))
    echo "Resource group ${resource_group_name} deleted successfully in ${total_time} seconds."
}

cleanup_terraform_states() {
    local modules=(
        "../modules/adb-workspace"
        "../modules/metastore-and-users"
        "../modules/adb-unity-catalog"
    )

    for module in "${modules[@]}"; do
        if [[ -d "${module}" ]]; then
            echo "Cleaning up Terraform state files in module: ${module}"
            rm -f "${module}/terraform.tfstate" "${module}/terraform.tfstate.backup"
            rm -rf "${module}/.terraform"
            echo "State files cleaned up in module: ${module}"
        else
            echo "Module path does not exist: ${module}"
        fi
    done
}


main() {
    load_env_variables
    check_resource_group_name
    delete_resource_group
    cleanup_terraform_states
    echo "All tasks completed successfully."
}


main
