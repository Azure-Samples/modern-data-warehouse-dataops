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

    if [ "$2" == "info" ] ; then
        COLOR="96m";
    elif [ "$2" == "success" ] ; then
        COLOR="92m";
    elif [ "$2" == "warning" ] ; then
        COLOR="93m";
    elif [ "$2" == "danger" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR" "$1";
}

ifexistsoverwrite() {
    declare pipeline_name=$1
    full_pipeline_name=$PROJECT-$pipeline_name
    
    if [[ -n "$(az pipelines show --name "$full_pipeline_name" --output json 2>/dev/null)" ]]; then
        pipeline_id=$(az pipelines show --name "$full_pipeline_name" --output json 2>/dev/null | jq -r .id)
        az pipelines delete --id "$pipeline_id" --yes
        echo "Deleted existing pipeline: $full_pipeline_name (Pipeline ID: $pipeline_id)"
    else
        echo "Pipeline $full_pipeline_name does not exist."
    fi
}

createPipeline ()
{
    declare pipeline_name=$1
    declare pipeline_description=$2
    full_pipeline_name=$PROJECT-$pipeline_name
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
