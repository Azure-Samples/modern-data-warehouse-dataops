#!/bin/bash
source .env

az account set --subscription "$AZURE_SUBSCRIPTION_ID"

onelake_name="onelake"
workspace_names=("ws-$FABRIC_PROJECT_NAME-dev" "ws-$FABRIC_PROJECT_NAME-uat" "ws-$FABRIC_PROJECT_NAME-prd")
deployment_pipeline_name="dp-$FABRIC_PROJECT_NAME"
deployment_pipeline_desc="Deployment pipeline for $FABRIC_PROJECT_NAME"
workspace_ids=()
lakehouse_name="lh_main"
lakehouse_desc="Lakehouse for $FABRIC_PROJECT_NAME"
notebook_name="nb-fabric-cicd"
azure_devops_details='{
    "gitProviderType":"'"AzureDevOps"'",
    "organizationName":"'"$ORGANIZATION_NAME"'",
    "projectName":"'"$PROJECT_NAME"'",
    "repositoryName":"'"$REPOSITORY_NAME"'",
    "branchName":"'"$BRANCH_NAME"'",
    "directoryName":"'"$DIRECTORY_NAME"'"
}'
deploy_azure_resources="true"
create_workspaces="true"
connect_to_git="true"
setup_deployment_pipeline="true"
create_default_lakehouse="true"
should_disconnect="false"
upload_notebook="true"
trigger_notebook_execution="true"

function create_resource_group () {
    resource_group_name="$1"
    arm_output=$(az group create --name "$resource_group_name" --location "$AZURE_LOCATION")
}

function deploy_azure_resources() {
    resource_group_name="$1"
    arm_output=$(az deployment group create \
        --resource-group "$resource_group_name" \
        --template-file infra/main.bicep \
        --parameters @infra/params.json \
        --parameters location="$AZURE_LOCATION" capacityName="$FABRIC_CAPACITY_NAME" \
        --output json)

    if [[ -z $arm_output ]]; then
        echo >&2 "[E] ARM deployment failed."
        exit 1
    else
        echo "[I] Capacity '$FABRIC_CAPACITY_NAME' created successfully."
    fi
}

function get_capacity_id() {
     response=$(curl -s -X GET "$FABRIC_API_ENDPOINT/capacities" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN")
     capacity_id=$(echo "${response}" | jq -r --arg var "$FABRIC_CAPACITY_NAME" '.value[] | select(.displayName == $var) | .id')
     echo "$capacity_id"
}

function create_workspace(){
     local workspace_name="$1"
     local capacity_id="$2"

     jsonPayload=$(cat <<EOF
{
     "DisplayName": "$workspace_name",
     "capacityId": "${capacity_id}",
     "description": "Workspace $workspace_name",
}
EOF
)

     curl -s -X POST "$FABRIC_API_ENDPOINT/workspaces" \
          -o /dev/null \
          -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" \
          -H "Content-Type: application/json" \
          -d "${jsonPayload}"

}

function get_workspace_id() {
    workspace_name=$1
    get_workspaces_url="$FABRIC_API_ENDPOINT/workspaces"
    workspaces=$(curl -s -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" "$get_workspaces_url" | jq -r '.value')
    workspace=$(echo "$workspaces" | jq -r --arg name "$workspace_name" '.[] | select(.displayName == $name)')
    workspace_id=$(echo "$workspace" | jq -r '.id')
    echo "$workspace_id"
}

function create_deployment_pipeline() {
    deployment_pipeline_name=$1
    deployment_pipeline_desc=$2
    deployment_pipeline_body=$(cat <<EOF
{
    "displayName": "$deployment_pipeline_name",
    "description": "$deployment_pipeline_desc"
}
EOF
)
    create_deployment_pipeline_url="$DEPLOYMENT_API_ENDPOINT"
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$deployment_pipeline_body" "$create_deployment_pipeline_url")
    deployment_pipeline_id=$(echo "$response" | jq -r '.id')
    echo "[I] Created deployment pipeline '$deployment_pipeline_name' ($deployment_pipeline_id) successfully."
}

function get_deployment_pipeline_id() {
    deployment_pipeline_name=$1
    get_pipelines_url="$DEPLOYMENT_API_ENDPOINT"
    pipelines=$(curl -s -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" "$get_pipelines_url" | jq -r '.value')
    pipeline=$(echo "$pipelines" | jq -r --arg name "$deployment_pipeline_name" '.[] | select(.displayName == $name)')
    pipeline_id=$(echo "$pipeline" | jq -r '.id')
    echo "$pipeline_id"
}

function get_deployment_pipeline_stages() {
    pipeline_id=$1
    get_pipeline_stages_url="$DEPLOYMENT_API_ENDPOINT/$pipeline_id/stages"
    stages=$(curl -s -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" "$get_pipeline_stages_url" | jq -r '.value')
    echo "$stages"
}

function unassign_workspace_from_stage() {
    pipeline_id=$1
    stage_id=$2
    pipeline_unassignment_url="$DEPLOYMENT_API_ENDPOINT/$pipeline_id/stages/$stage_id/unassignWorkspace"
    pipeline_unassignment_body={}

    curl -s -X POST -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$pipeline_unassignment_body" "$pipeline_unassignment_url"
    echo "[I] Unassigned workspace from stage '$stage_id' successfully."
}

function assign_workspace_to_stage() {
    pipeline_id=$1
    stage_id=$2
    workspace_id=$3
    pipeline_assignment_url="$DEPLOYMENT_API_ENDPOINT/$pipeline_id/stages/$stage_id/assignWorkspace"
    pipeline_assignment_body=$(cat <<EOF
{
    "workspaceId": "$workspace_id"
}
EOF
)
    curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$pipeline_assignment_body" "$pipeline_assignment_url"
    echo "[I] Assigned workspace '$workspace_id' to stage '$stage_id' successfully."
}

function create_item() {
    workspace_id=$1
    item_type=$2
    display_name=$3
    description=$4
    create_item_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/items"
    create_item_body=$(cat <<EOF
{
    "displayName": "$display_name",
    "description": "$description",
    "type": "$item_type"
}
EOF
)
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$create_item_body" "$create_item_url")
    lakehouse_id=$(echo "$response" | jq -r '.id')
    echo "[I] Created $item_type '$display_name' ($lakehouse_id) successfully."
}

function get_item_by_name_type() {
    workspace_id=$1
    item_type=$2
    item_name=$3

    get_items_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/items"
    items=$(curl -s -X GET -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" "$get_items_url" | jq -r '.value')
    item=$(echo "$items" | jq -r --arg name "$item_name" --arg type "$item_type" '.[] | select(.displayName == $name and .type == $type)')
    item_id=$(echo "$item" | jq -r '.id')
    echo "$item_id"
}

function disconnect_workspace_from_git() {
    workspace_id=$1
    disconnect_workspace_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/git/disconnect"
    disconnect_workspace_body={}
    response=$(curl -s -X POST -H "Authorization : Bearer $FABRIC_BEARER_TOKEN" -d "$disconnect_workspace_body" "$disconnect_workspace_url")
    if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
        error_code=$(echo "$response" | jq -r '.errorCode')
        if [[ "$error_code" = "WorkspaceNotConnectedToGit" ]]; then
            echo "[I] Workspace is not connected to git."
        else
            echo "[E] The workspace disconnection from git failed."
            echo "[E] $response"
        fi
    else
        echo "[I] Workspace disconnected from the git repository."
    fi
}

function initialize_connection() {
    workspace_id=$1
    initialize_connection_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/git/initializeConnection"
    initialize_connection_body='{"InitializationStrategy": "PreferWorkspace"}'
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization : Bearer $FABRIC_BEARER_TOKEN" -d "$initialize_connection_body" "$initialize_connection_url")
    echo "[I] The Git connection has been successfully initialized."
}

function connect_workspace_to_git() {
    workspace_id=$1
    git_provider_details=$2
    connect_workspace_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/git/connect"
    connect_workspace_body='{"gitProviderDetails": '"$git_provider_details"'}'
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$connect_workspace_body" "$connect_workspace_url")
    if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
        error_code=$(echo "$response" | jq -r '.errorCode')
        if [[ "$error_code" = "WorkspaceAlreadyConnectedToGit" ]]; then
            echo "[I] Workspace is already connected to git."
        else
            echo "[E] The workspace connection to git failed."
            echo "[E] $response"
        fi
    else
        echo "[I] Workspace connected to the git repository."
        initialize_connection "$dev_workspace_id"
    fi
}

function get_git_status() {
    workspace_id=$1
    get_git_status_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/git/status"
    response=$(curl -s -X GET -H "Authorization : Bearer $FABRIC_BEARER_TOKEN" "$get_git_status_url")
    workspace_head=$(echo "$response" | jq -r '.workspaceHead')
    echo "$workspace_head"
}

function commit_all_to_git() {
    workspace_id=$1
    workspace_head=$2
    commit_message=$3
    commit_all_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/git/commitToGit"
    commit_all_body=$(cat <<EOF
{
    "mode": "All",
    "comment": "$commit_message",
    "workspaceHead": "$workspace_head"
}
EOF
)
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$commit_all_body" "$commit_all_url")
    if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
        error_code=$(echo "$response" | jq -r '.errorCode')
        if [[ "$error_code" = "NoChangesToCommit" ]]; then
            echo "[I] There are no changes to commit."
        else
            echo "[E] Committing workspace changes to git failed."
            echo "[E] $response"
        fi
    else
        echo "[I] Committed workspace changes to git successfully."
    fi
}

# TBD: Add metadata section to the notebook to attach it to default lakehouse before the upload.
function upload_notebook() {
    workspace_id=$1
    item_type=$2
    display_name=$3
    payload=$4
    create_item_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/items"
    create_item_payload=$(cat <<EOF
{
    "displayName": "$display_name",
    "type":"$item_type",
    "definition" : {
        "format": "ipynb",
        "parts": [
            {
                "path": "artifact.content.ipynb",
                "payload": "$payload",
                "payloadType": "InlineBase64"
            }
        ]
    }
}
EOF
)
    # TBD: Check the notebook creation via polling long running operation. Read header response using "-i" flag.
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$create_item_payload" "$create_item_url")
    sleep 30
    notebook_id=$(get_item_by_name_type "$workspace_id" "Notebook" "$display_name")
    echo "[I] Created (uploaded) $item_type '$display_name' ($notebook_id) successfully."
}

function execute_notebook() {
    workspace_id=$1
    item_id=$2
    workspace_name=$3
    lakehouse_name=$4
    onelake_name=$5
    execute_notebook_url="$FABRIC_API_ENDPOINT/workspaces/$workspace_id/items/$item_id/jobs/instances?jobType=RunNotebook"
    execute_notebook_body=$(cat <<EOF
{
    "executionData": {
        "parameters": {
            "workspace_name": {
                "value": "$workspace_name",
                "type": "string"
            },
            "lakehouse_name": {
                "value": "$lakehouse_name",
                "type": "string"
            },
            "onelake_name": {
                "value": "$onelake_name",
                "type": "string"
            }
        },
        "configuration": {
            "useStarterPool": true
        }
    }
}
EOF
)
    # TBD: Check the notebook execution via polling long running operation. Read header response by using "-i" flag.
    response=$(curl -s -X POST -H "Authorization: Bearer $FABRIC_BEARER_TOKEN" -d "$execute_notebook_body" "$execute_notebook_url")
    if [[ -n "$response" ]] && [[ "$response" != "null" ]]; then
        echo "[E] Notebook execution failed."
        echo "[E] $response"
    else
        echo "[I] Notebook execution triggered successfully."
    fi
}

if [[ "$deploy_azure_resources" = "true" ]]; then
    resource_group_name="$RESOURCE_GROUP_NAME"
    echo "[I] Creating resource group '$resource_group_name'"
    create_resource_group "$resource_group_name"

    echo "[I] Deploying Azure resources to resource group '$resource_group_name'"
    deploy_azure_resources "$resource_group_name"
else
    echo "[I] Variable 'deploy_azure_resources' set to $deploy_azure_resources, skipping Azure resource deployment."
fi

echo "[I] --- Starting workspace creation. ---"
if [[ "$create_workspaces" = "true" ]]; then
    capacity_id=$(get_capacity_id)
    echo "[I] Fabric capacity is '$FABRIC_CAPACITY_NAME' ($capacity_id)"

    for ((i=0; i<${#workspace_names[@]}; i++)); do
        workspace_ids[i]=$(get_workspace_id "${workspace_names[$i]}")
        if [[ -n "${workspace_ids[i]}" ]]; then
            echo "[W] Workspace: '${workspace_names[$i]}' (${workspace_ids[i]}) already exists."
            echo "[W] Please verify the attached capacity manually."
        else
            create_workspace "${workspace_names[$i]}" "$capacity_id"
            workspace_ids[i]=$(get_workspace_id "${workspace_names[$i]}")
            echo "[I] Created workspace '${workspace_names[i]}' (${workspace_ids[i]})"
        fi
    done
else
    echo "[I] Variable 'create_workspaces' set to $create_workspaces, skipping workspace creation."
fi

# TBD: Name each stage in the deployment pipeline.
# TBD: Remove dependency on "create_workspaces" variable set to "true" for the setup of deployment pipeline.
echo "[I] --- Completed workspace creation. Moving to setting up deployment pipeline. ---"
if [[ "$setup_deployment_pipeline" = "true" ]]; then
    pipeline_id=$(get_deployment_pipeline_id "$deployment_pipeline_name")

    if [[ -n "$pipeline_id" ]]; then
        echo "[I] Deployment pipeline '$deployment_pipeline_name' ($pipeline_id) already exists."
    else
        echo "[I] No deployment pipeline with name '$deployment_pipeline_name' found, creating one."
        create_deployment_pipeline "$deployment_pipeline_name" "$deployment_pipeline_desc"
        pipeline_id=$(get_deployment_pipeline_id "$deployment_pipeline_name")
    fi

    pipeline_stages=$(get_deployment_pipeline_stages "$pipeline_id")

    for ((i=0; i<${#workspace_names[@]}; i++)); do
        workspace_name="${workspace_names[i]}"
        workspace_id="${workspace_ids[i]}"
        echo "[I] Workspace $workspace_name ($workspace_id)"
        existing_workspace_id=$(echo "$pipeline_stages" | jq -r --arg order "$i" '.[] | select(.order == ($order | tonumber) and .workspaceId) | .workspaceId')
        echo "[I] Existing workspace for stage '$i' is $existing_workspace_id."
        if [[ -z "$existing_workspace_id" ]]; then
            assign_workspace_to_stage "$pipeline_id" "$i" "$workspace_id"
        elif [[ "$existing_workspace_id" == "$workspace_id" ]]; then
            echo "[I] The pipeline deployment stage '$i' has workspace '$workspace_name' ($workspace_id) already assigned to it."
        else
            echo "[I] The pipeline deployment stage '$i' has a different workspace '$workspace_name' ($workspace_id) assigned, reassigning."
            unassign_workspace_from_stage "$pipeline_id" "$i"
            assign_workspace_to_stage "$pipeline_id" "$i" "$workspace_id"
        fi
    done
else
    echo "[I] Variable 'setup_deployment_pipeline' set to $setup_deployment_pipeline, skipping deployment pipeline creation."
fi

dev_workspace_id="${workspace_ids[0]}"
dev_workspace_name="${workspace_names[0]}"

echo "[I] --- Completed deployment pipeline creation. Moving to lakehouse creation in DEV workspace. ---"
if [[ "$create_default_lakehouse" = "true" ]]; then
    item_id=$(get_item_by_name_type "$dev_workspace_id" "Lakehouse" "$lakehouse_name")
    if [[ -n "$item_id" ]]; then
        echo "[I] Lakehouse $lakehouse_name ($item_id) already exists."
    else
        create_item "$dev_workspace_id" "Lakehouse" "$lakehouse_name" "$lakehouse_desc"
    fi
else
    echo "[I] Variable 'create_default_lakehouse' set to $create_default_lakehouse, skipping lakehouse creation."
fi

# TBD: If the notebook exists, update the notebook with the latest version.
# https://learn.microsoft.com/en-us/rest/api/fabric/core/items/update-item-definition?tabs=HTTP
echo "[I] --- Completed lakehouse creation. Uploading notebook to DEV workspace. ---"
if [[ "$upload_notebook" = "true" ]]; then
    file_path="./src/common/notebooks/${notebook_name}.ipynb"
    base64_data=$(base64 -i "$file_path")
    item_id=$(get_item_by_name_type "$dev_workspace_id" "Notebook" "$notebook_name")
    if [[ -n "$item_id" ]]; then
        echo "[I] Notebook '$notebook_name' ($item_id) already exists, skipping the upload."
    else
        upload_notebook "$dev_workspace_id" "Notebook" "$notebook_name" "$base64_data"
    fi
else
    echo "[I] Variable 'upload_notebook' set to $upload_notebook, skipping notebook upload."
fi

echo "[I] --- Completed Uploading notebook to DEV workspae. Triggering the notebook execution. ---"
if [[ "$trigger_notebook_execution" = "true" ]]; then
    item_id=$(get_item_by_name_type "$dev_workspace_id" "Notebook" "$notebook_name")
    execute_notebook "$dev_workspace_id" "$item_id" "$dev_workspace_name" "$lakehouse_name" "$onelake_name"
    # TBD: Check the notebook execution via polling long running operation.
else
    echo "[I] Variable 'trigger_notebook_execution' set to $trigger_notebook_execution, skipping notebook execution."
fi

echo "[I] --- Triggered the notebook execution. Now integrating GIT with DEV workspace and commiting changes to git. ---"
if [[ "$connect_to_git" = "true" ]]; then
    if [ "$should_disconnect" = true ]; then
        disconnect_workspace_from_git "$dev_workspace_id"
    fi
    connect_workspace_to_git "$dev_workspace_id" "$azure_devops_details"
    workspace_head=$(get_git_status "$dev_workspace_id")
    commit_all_to_git "$dev_workspace_id" "$workspace_head" "Committing initial changes"
else
    echo "[I] Variable 'connect_to_git' set to $connect_to_git, skipping git integration, commit and push."
fi