#!/bin/bash

#######################################################
# Deploys Azure DevOps Azure Service Connections
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
# - Correct Azure DevOps Project selected
###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# ENV_NAME
# DEPLOYMENT_ID
# TENANT_ID
# AZDO_PROJECT
# AZDO_ORGANIZATION_URL
#######################################################

set -o errexit
set -o pipefail
set -o nounset

verify_environment() {
    # Check if required environment variables are set
    if [[ -z "${PROJECT:-}" || -z "${ENV_NAME:-}" || -z "${DEPLOYMENT_ID:-}" || -z "${TENANT_ID:-}" || -z "${AZDO_PROJECT:-}" || -z "${AZDO_ORGANIZATION_URL:-}" ]]; then
        log "Required environment variables (PROJECT, ENV_NAME, DEPLOYMENT_ID, TENANT_ID, AZDO_PROJECT, AZDO_ORGANIZATION_URL) are not set." "error"
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log "jq is not installed. Please install jq to proceed." "error"
        exit 1
    fi

  ###########################################
  # Setup Azure service connection variables
  ###########################################
  az_service_connection_name="${PROJECT}-serviceconnection-$ENV_NAME"
  az_sub=$(az account show --output json)
  az_sub_id=$(echo "$az_sub" | jq -r '.id')
  az_sub_name=$(echo "$az_sub" | jq -r '.name')
}

delete_existing_service_connection() {
    # Check if the service connection already exists
    sc_id=$(az devops service-endpoint list --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "[?name=='$az_service_connection_name'].id" --output tsv)
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
        log "Successfully deleted service connection: $sc_id", "success"
    fi
}

create_azdo_service_connection() {
  log "Creating Azure DevOps Service Connection for Azure..." "info"

  #Project ID
  project_id=$(az devops project show --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query id --output tsv)
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

  log "Create a new service connection" "info"

  # Create the service connection using the Azure DevOps CLI
  response=$(az devops service-endpoint create --service-endpoint-configuration ./devops.json --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT")

  # Check if the service connection was created successfully by checking if the operationStatus state is "Ready"
  # Else display error message
  sc_id=$(echo "$response" | jq -r '.id')
  if [ -n "$sc_id" ]; then    
      log "Created Connection: $sc_id" "success"
      # Wait until operationStatus.state is Ready or Failed, keep checking
      response=$(az devops service-endpoint show --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "operationStatus.state" --output tsv)
      until [[ "$response" == "Ready" || "$response" == "Failed"  ]]; do
          log "Service Connection creation state is $response. Waiting for it to be Ready..." "info"
          sleep 5
          response=$(az devops service-endpoint show --id "$sc_id" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "operationStatus.state" --output tsv)
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

  az devops service-endpoint update --id "$sc_id" --enable-for-all "true" --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --output none

  # Remove the JSON config file if exists
  if [ -f ./devops.json ]; then
      rm ./devops.json
      log "Removed the JSON config file: ./devops.json" "info"
  fi
}

deploy_azdo_service_connections_azure() {
    log "Deploying Azure DevOps Service Connections for Azure..." "info"
    verify_environment
    delete_existing_service_connection
    create_azdo_service_connection
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd ..
    . ./scripts/common.sh
    . ./scripts/init_environment.sh
    set_deployment_environment "dev"
    deploy_azdo_service_connections_azure
    popd
else
    . ./scripts/common.sh
    deploy_azdo_service_connections_azure
fi