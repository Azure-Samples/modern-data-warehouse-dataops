#!/bin/bash

# Globals and constants
export TIMESTAMP=$(date +%s)
export RED='\033[0;31m'
export ORANGE='\033[0;33m'
export NC='\033[0m'

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
        "success")
            COLOR="92m"
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

delete_azdo_pipeline_if_exists() {
    declare full_pipeline_name=$1
    
    ## when returning a pipeline that does exist, delete.
    
    pipeline_output=$(az pipelines list --query "[?name=='$full_pipeline_name']" --output json)
    pipeline_id=$(echo "$pipeline_output" | jq -r '.[0].id')
    
    if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
        log "No Deployment pipeline with name $full_pipeline_name found."
    else
        az pipelines delete --id "$pipeline_id" --yes 1>/dev/null
        log "Deleted existing pipeline: $full_pipeline_name (Pipeline ID: $pipeline_id)"
    fi
}

create_azdo_pipeline ()
{
    declare pipeline_name=$1
    declare pipeline_description=$2
    full_pipeline_name=$PROJECT-$pipeline_name

    delete_azdo_pipeline_if_exists "$full_pipeline_name"
    log "Creating deployment pipeline: $full_pipeline_name"

    pipeline_id=$(az pipelines create \
        --name "$full_pipeline_name" \
        --description "$pipeline_description" \
        --repository "$GITHUB_REPO_URL" \
        --branch "$AZDO_PIPELINES_BRANCH_NAME" \
        --yaml-path "/e2e_samples/parking_sensors/devops/azure-pipelines-$pipeline_name.yml" \
        --service-connection "$github_sc_id" \
        --skip-first-run true \
        --output json | jq -r '.id')
    echo "$pipeline_id"
}

databricks_cluster_exists () {
    declare cluster_name="$1"
    declare cluster=$(databricks clusters list | tr -s " " | cut -d" " -f2 | grep ^${cluster_name}$)
    if [[ -n $cluster ]]; then
        return 0; # cluster exists
    else
        return 1; # cluster does not exists
    fi
}


create_adf_linked_service () {
    declare name=$1
    log "Creating ADF LinkedService: $name"
    adfLsUrl="${adfFactoryBaseUrl}/linkedservices/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfLsUrl" --body @"${ADF_DIR}"/linkedService/"${name}".json
}
create_adf_dataset () {
    declare name=$1
    log "Creating ADF Dataset: $name"
    adfDsUrl="${adfFactoryBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfDsUrl" --body @"${ADF_DIR}"/dataset/"${name}".json
}
create_adf_pipeline () {
    declare name=$1
    log "Creating ADF Pipeline: $name"
    adfPUrl="${adfFactoryBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfPUrl" --body @"${ADF_DIR}"/pipeline/"${name}".json
}
create_adf_trigger () {
    declare name=$1
    log "Creating ADF Trigger: $name"
    adfTUrl="${adfFactoryBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfTUrl" --body @"${ADF_DIR}"/trigger/"${name}".json
}

# Function to give time for the portal to process the cleanup
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal $seconds seconds to process the information..."
    sleep "$seconds"
}

cleanup_federated_credentials() {
    ##Function used in the Clean_up.sh and deploy_azdo_service_connections_azure.sh scripts
    local sc_id=$1
    local spnAppObjId=$(az devops service-endpoint show --id "$sc_id" --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT" --query "data.appObjectId" -o tsv)
    local spnCredlist=$(az ad app federated-credential list --id "$spnAppObjId" --query "[].id" -o json)
    log "Found existing federated credentials. Deleting..."

    # Sometimes the Azure Portal needs a little bit more time to process the information.
    if [ -z "$spnCredlist" ]; then
        log "It was not possible to list Federated credentials for Service Principal. Retrying once more.."
        wait_for_process
        local spnCredlist=$(az ad app federated-credential list --id "$spnAppObjId" --query "[].id" -o json)
        if [ -z "$spnAppObjId" ]; then
            log "It was not possible to list Federated credentials for specified Service Principal."
            return
        fi
    fi
    
    local credArray=($(echo "$spnCredlist" | jq -r '.[]'))
    #(&& and ||) to log success or failure of each delete operation
    for cred in "${credArray[@]}"; do
        az ad app federated-credential delete --federated-credential-id "$cred" --id "$spnAppObjId" &&
        log "Deleted federated credential: $cred" || 
        log "Failed to delete federated credential: $cred"
    done
    # Refresh the list of federated credentials
    spnCredlist=$(az ad app federated-credential list --id "$spnAppObjId" --query "[].id" -o json)
    if [ "$(echo "$spnCredlist" | jq -e '. | length > 0')" = "true" ]; then
        log "Failed to delete federated credentials"
        exit 1
    fi
  log "Completed federated credential cleanup for the Service Principal: $spnAppObjId"
}

