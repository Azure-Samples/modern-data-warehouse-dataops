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




# Retry a command up to a specific numer of times until it exits successfully,
# with exponential back off.
#
#  $ retry 5 echo Hello
#  Hello
#
#  $ retry 5 false
#  Retry 1/5 exited 1, retrying in 1 seconds...
#  Retry 2/5 exited 1, retrying in 2 seconds...
#  Retry 3/5 exited 1, retrying in 4 seconds...
#  Retry 4/5 exited 1, retrying in 8 seconds...
#  Retry 5/5 exited 1, no more retries left.
#  
# source; https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746
function retry {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** count))
    count=$((count + 1))
    if [ $count -lt "$retries" ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}


# There is a delay between creating a service principal and when it is ready for use.
# This helper function blocks deployment till Service Principal is ready for use.
# Usage: wait_service_principal_creation <SERVICE_PRINCIPAL_APP_ID>
wait_service_principal_creation () {
    local sp_app_id=$1
    until az ad sp list --show-mine --query "[].appId" -o tsv | grep "$sp_app_id"
    do
        echo "waiting for service principal to finish creating..."
        sleep 10
    done
    # Now, try to retrieve it
    retry 10 az ad sp show --id "$sp_app_id" --query "id"
}

# Assign an Azure Synapse role to an SP if not already assigned
# Sample usage: assign_synapse_role_if_not_exists "<SYNAPSE_WORKSPACE_NAME" "Synapse Administrator" "<SERVICE_PRINCIPAL_OBJECT_ID>"
assign_synapse_role_if_not_exists() {
    local syn_workspace_name=$1
    local syn_role_name=$2
    local sp_obj_id=$3
    # Retrieve roleDefinitionId
    syn_role_id=$(az synapse role definition show --workspace-name "$syn_workspace_name" --role "$syn_role_name" --query id --output tsv)
    role_exists=$(az synapse role assignment list --workspace-name "$syn_workspace_name" \
        --query="[?principalId == '$sp_obj_id' && roleDefinitionId == '$syn_role_id']" -o tsv)
    if [[ -z $role_exists ]]; then
        retry 10 az synapse role assignment create --workspace-name "$syn_workspace_name" \
            --role "$syn_role_name" --assignee-object-id "$sp_obj_id"
    else
        echo "$syn_role_name role exists for service principal with object id: $sp_obj_id"
    fi
}

# Assign an Azure Storage role to an SP if not already assigned
# Sample usage: assign_storage_role "<STORAGE_ACCOUNT_NAME>" "<RESOUCE_GROUP_NAME>" "Storage Blob Data Contributor" "<SERVICE_PRINCIPAL_OBJECT_ID>"
assign_storage_role() {
    local storage_account_name=$1
    local resource_group_name=$2
    local stor_role_name=$3
    local sp_obj_id=$4

    # Get Storage Account scope
    storage_account_scope=$(az storage account show -g "$resource_group_name" -n "$storage_account_name" --query id -o tsv)

    # Assign Role Assignment
    az role assignment create --role "$stor_role_name" --assignee "$sp_obj_id" --scope "$storage_account_scope"
}