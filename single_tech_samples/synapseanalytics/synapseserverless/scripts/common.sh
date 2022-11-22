#!/bin/bash

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

# Assign an Azure Synapse role to the sign in user
# Sample usage: assign_synapse_role_if_not_exists "<SYNAPSE_WORKSPACE_NAME" "Synapse Administrator" "<SERVICE_PRINCIPAL_NAME>"
assign_synapse_role_if_not_exists() {
    local syn_workspace_name=$1
    local syn_role_name=$2
    local sp_name_or_obj_id=$3
    # Retrieve roleDefinitionId
    syn_role_id=$(az synapse role definition show --workspace-name "$syn_workspace_name" --role "$syn_role_name" -o json | jq -r '.id')
    role_exists=$(az synapse role assignment list --workspace-name "$syn_workspace_name" \
        --query="[?principalId == '$sp_name_or_obj_id' && roleDefinitionId == '$syn_role_id']" -o tsv)
    if [[ -z $role_exists ]]; then
        retry 10 az synapse role assignment create --workspace-name "$syn_workspace_name" \
            --role "$syn_role_name" --assignee "$sp_name_or_obj_id"
    else
        echo "$syn_role_name role exists for $sp_name_or_obj_id"
    fi
}