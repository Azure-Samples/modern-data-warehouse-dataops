#!/bin/bash

# Source enviroment variables
. .devcontainer/.env

get_env_names() {
    env_deploy=$1

    case ${env_deploy} in
    1)
        log "Deploying Dev Environment only..." "info"
        env_names="dev"
        ;;
    2)    
        log "Deploying Dev and Stage Environments..." "info"
        env_names="dev stg"
        ;;
    3) 
        log "Full Deploy: Dev, Stage and Prod Environments..." "info"
        env_names="dev stg prod"
        ;;
    *)
        log "Invalid choice. Exiting..." "error"
        exit
        ;;
    esac
    echo "$env_names" > /dev/null
}

set_deployment_environment () {
    env_name=$1
    if [ -z "${env_name}" ]; then
        log "Environment name is not set. Exiting." "error"
        exit 1
    fi
    kv_name="$PROJECT-kv-${env_name}-$DEPLOYMENT_ID"
    cat_stg_account_name="${PROJECT}catalog${env_name}${DEPLOYMENT_ID}"
    data_stg_account_name="${PROJECT}st${env_name}${DEPLOYMENT_ID}"
    resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-${env_name}-rg"
    mng_resource_group_name="${PROJECT}-${DEPLOYMENT_ID}-dbw-${env_name}-rg"
    stg_credential_name="${PROJECT}-${DEPLOYMENT_ID}-stg-credential-${env_name}"
    catalog_ext_location_name="${PROJECT}-catalog-${DEPLOYMENT_ID}-ext-location-${env_name}"
    data_ext_location_name="${PROJECT}-data-${DEPLOYMENT_ID}-ext-location-${env_name}"
    catalog_name="${PROJECT}-${DEPLOYMENT_ID}-catalog-${env_name}"
}

# Helper functions
random_str() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1 | tr '[:upper:]' '[:lower:]'
    return 0
}

print_style () {
    case "$2" in
        "info")
            COLOR="96m"
            ;;
        "debug")
            COLOR="96m"
            ;;
        "success")
            COLOR="92m"
            ;;
        "error")
            COLOR="91m"
            ;;
        "warning")
            COLOR="93m"
            ;;
        "danger")
            COLOR="91m"
            ;;
        "action")
            COLOR="32m"
            ;;
        *)
            COLOR="0m"
            ;;
    esac

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"
    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
}

log() {
    # This function takes a string as an argument and prints it to the console to stderr
    # if a second argument is provided, it will be used as the style of the message
    # Usage: log "message" "style"
    # Example: log "Hello, World!" "info"
    local message=$1
    local style=${2:-}

    if [[ -z "$style" ]]; then
        echo -e "$(print_style "$message" "default")" >&2
    else
        echo -e "$(print_style "$message" "$style")" >&2
    fi
}

# Function to give time for the portal to process the cleanup
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal $seconds seconds to process the information..." "info"
    sleep "$seconds"
}

delete_azdo_service_connection_principal(){
    # This function deletes the Service Principal associated with the provided AzDO Service Connection
    local sc_id=$1
    local spnAppObjId=$(az devops service-endpoint show --id "$sc_id" --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT" --query "data.appObjectId" --output tsv)
    if [ -z "$spnAppObjId" ]; then
        log "Service Principal Object ID not found for Service Connection ID: $sc_id. Skipping Service Principal cleanup." "info"
        return
    fi
    log "Attempting to delete Service Principal." "info"
    az ad app delete --id "$spnAppObjId" &&
        log "Deleted Service Principal: $spnAppObjId" "info" || 
        log "Failed to delete Service Principal: $spnAppObjId" "info"
}
