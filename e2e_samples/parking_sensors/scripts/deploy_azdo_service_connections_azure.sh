#!/bin/bash

#######################################################
# Deploys Azure DevOps Azure Service Connections
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset


###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# ENV_NAME
# DEPLOYMENT_ID
# TENANT_ID
# AZDO_PROJECT
# AZDO_ORGANIZATION_URL
# RESOURCE_GROUP_NAME
###############

. ./scripts/common.sh

###########################################
# Setup Azure service connection variables
###########################################
az_service_connection_name="${PROJECT}-serviceconnection-$ENV_NAME"
az_sub=$(az account show --output json)
az_sub_id=$(echo "$az_sub" | jq -r '.id')
az_sub_name=$(echo "$az_sub" | jq -r '.name')


# Check if the service connection already exists and delete it if found
sc_id=$(az devops service-endpoint list --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "[?name=='$az_service_connection_name'].id" -o tsv)
if [ -n "$sc_id" ]; then
    log "Service connection: $az_service_connection_name already exists. Deleting service connection id $sc_id ..." "info"
    # Delete AzDO service connection SPN if exists
    delete_azdo_service_connection_principal $sc_id
    wait_for_process 20 # Need to wait until the SPN deletion is processed
    # Delete AzDO service connection
    delete_response=$(az devops service-endpoint delete --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" -y )
    if echo "$delete_response" | grep -q "TF400813"; then
        log "Failed to delete service connection: $sc_id" "danger"
        exit 1
    fi
    log "Successfully deleted service connection: $sc_id"
fi

#Project ID
project_id=$(az devops project show --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query id -o tsv)
# JSON config file
cat <<EOF > ./devops.json
{
    "data": {
      "subscriptionId": "$az_sub_id",
      "subscriptionName": "$az_sub_name",
      "creationMode": "Automatic",
      "environment": "AzureCloud",
      "identityType": "AppRegistrationAutomatic",
      "scopeLevel": "Subscription"
    },
    "name": "$az_service_connection_name",
    "type": "azurerm",
    "owner": "library",
    "url": "https://management.azure.com/",
    "authorization": {
      "scheme": "WorkloadIdentityFederation",
      "parameters": {
        "tenantid": "$TENANT_ID",
        "scope": "/subscriptions/$az_sub_id/resourcegroups/$RESOURCE_GROUP_NAME"
      }
    },
    "isShared": false,
    "isOutdated": false,
    "serviceEndpointProjectReferences": [
        {
          "description": "",
          "name": "$az_service_connection_name",
          "projectReference": {
            "id": "$project_id",
            "name": "$AZDO_PROJECT"
          }
        }
    ]
}
EOF

log "Create a new service connection"

# Create the service connection using the Azure DevOps CLI
response=$(az devops service-endpoint create --service-endpoint-configuration ./devops.json --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT")

# Check if the service connection was created successfully by checking if the operationStatus state is "Ready"
# Else display error message
sc_id=$(echo "$response" | jq -r '.id')
if [ -n "$sc_id" ]; then    
    log "Created Connection: $sc_id"
    # Wait until operationStatus.state is Ready or Failed, keep checking
    response=$(az devops service-endpoint show --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "operationStatus.state" -o tsv)
    until [[ "$response" == "Ready" || "$response" == "Failed"  ]]; do
        log "Service Connection creation state is $response. Waiting for it to be Ready..."
        sleep 5
        response=$(az devops service-endpoint show --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "operationStatus.state" -o tsv)
    done
    if [[ "$response" == "Ready" ]]; then
        log "Service connection created successfully" "success"
    else
        log "Failed to create service connection" "danger"
        exit 1
    fi
else
    log "Failed to create service connection" "danger"
    exit 1
fi


az devops service-endpoint update --id "$sc_id" --enable-for-all "true" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" -o none

# Remove the JSON config file if exists
if [ -f ./devops.json ]; then
    rm ./devops.json
    log "Removed the JSON config file: ./devops.json"
else
    log "JSON config file does not exist: ./devops.json"
fi