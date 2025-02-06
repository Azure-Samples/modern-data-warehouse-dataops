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
    az rest --method put --uri "$adfLsUrl" --body @"${ADF_DIR}"/linkedService/"${name}".json -o none
}
create_adf_dataset () {
    declare name=$1
    log "Creating ADF Dataset: $name"
    adfDsUrl="${adfFactoryBaseUrl}/datasets/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfDsUrl" --body @"${ADF_DIR}"/dataset/"${name}".json -o none
}
create_adf_pipeline () {
    declare name=$1
    log "Creating ADF Pipeline: $name"
    adfPUrl="${adfFactoryBaseUrl}/pipelines/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfPUrl" --body @"${ADF_DIR}"/pipeline/"${name}".json -o none
}
create_adf_trigger () {
    declare name=$1
    log "Creating ADF Trigger: $name"
    adfTUrl="${adfFactoryBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$adfTUrl" --body @"${ADF_DIR}"/trigger/"${name}".json -o none
}

# Function to give time for the portal to process the cleanup
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal $seconds seconds to process the information..."
    sleep "$seconds"
}

delete_azdo_service_connection_principal(){
    # This function deletes the Service Principal associated with the provided AzDO Service Connection
    local sc_id=$1
    local spnAppObjId=$(az devops service-endpoint show --id "$sc_id" --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT" --query "data.appObjectId" -o tsv)
    if [ -z "$spnAppObjId" ]; then
        log "Service Principal Object ID not found for Service Connection ID: $sc_id. Skipping Service Principal cleanup."
        return
    fi
    log "Attempting to delete Service Principal."
    az ad app delete --id "$spnAppObjId" &&
    log "Deleted Service Principal: $spnAppObjId" || 
    log "Failed to delete Service Principal: $spnAppObjId"
}

deploy_infrastructure_environment() {
  ##function to allow user deploy enviromnents
    ## 1) Only Dev
    ## 2) Dev and Stage
    ## 3)  Dev, Stage and Prod
  ##Default  is option 3.
  ENV_DEPLOY=${1:-3}
  project=${2:-mdwdops}
    case $ENV_DEPLOY in
    1)
        log "Deploying Dev Environment only..."
        env_names="dev"
        ;;
    2)    
        log "Deploying Dev and Stage Environments..."    
        env_names="dev stg"
        ;;
    3) 
        log "Full Deploy: Dev, Stage and Prod Environments..."
        env_names="dev stg prod"
        ;;
    *)
        log "Invalid choice. Exiting..." "warning"
        exit
        ;;
    esac

    # Loop through the environments and deploy
    for env_name in $env_names; do
        echo "Currently deploying to the environment: $env_name"
        export PROJECT=$project
        export DEPLOYMENT_ID=$DEPLOYMENT_ID
        export ENV_NAME=$env_name
        export AZURE_LOCATION=$AZURE_LOCATION
        export AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
        export AZURESQL_SERVER_PASSWORD=$AZURESQL_SERVER_PASSWORD
        bash -c "./scripts/deploy_infrastructure.sh" || {
            echo "Deployment failed for $env_name"
            exit 1
        }
         export ENV_DEPLOY=$ENV_DEPLOY

    done

}
