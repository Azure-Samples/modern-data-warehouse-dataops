#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.


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
# RESOURCE_GROUP_NAME
# DEPLOYMENT_ID
###############

. ./scripts/common.sh

###########################################
# Setup Azure service connection variables
###########################################
az_service_connection_name="${PROJECT}-serviceconnection-$ENV_NAME"
az_sub=$(az account show --output json)
az_sub_id=$(echo "$az_sub" | jq -r '.id')
az_sub_name=$(echo "$az_sub" | jq -r '.name')
##Otherwise the listing azdo service will fail
role="Owner"


#Project ID
project_id=$(az devops project show --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query id -o tsv)
log "Project ID: $project_id"

# Check if the service connection already exists and delete it if found
sc_id=$(az devops service-endpoint list --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "[?name=='$az_service_connection_name'].id" -o tsv)
if [ -n "$sc_id" ]; then
    log "Service connection: $az_service_connection_name already exists. Deleting service connection id $sc_id ..." "info"
    cleanup_federated_credentials "$sc_id"
    wait_for_cleanup

  #Delete azdo service connection
  delete_response=$(az devops service-endpoint delete --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" -y )
  if echo "$delete_response" | grep -q "TF400813"; then
      log "Failed to delete service connection: $delete_response"
      exit 1
  fi
  log "Successfully deleted service connection: $delete_response"

fi

# JSON config file
cat <<EOF > ./devops.json
{
    "data": {
      "subscriptionId": "$az_sub_id",
      "subscriptionName": "$az_sub_name",
      "creationMode": "Automatic",
      "environment": "AzureCloud",
      "scopeLevel": "Subscription"
    },
    "name": "$az_service_connection_name",
    "type": "azurerm",
    "url": "https://management.azure.com/",
    "authorization": {
      "scheme": "WorkloadIdentityFederation",
      "parameters": {
        "tenantid": "$TENANT_ID",
        "scope": "/subscriptions/$az_sub_id/resourcegroups/$RESOURCE_GROUP_NAME"
      }
    },
    "isShared": false,
    "isReady": true,
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
sc_id=$(echo "$response" | jq -r '.id')
log "Created Connection: $response"

if [ -z "$sc_id" ]; then
    log "Failed to create service connection"
    exit 1
fi

az devops service-endpoint update --id "$sc_id" --enable-for-all "true" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL"

# Remove the JSON config file
rm ./devops.json
log "Removed the JSON config file: ./devops.json"
