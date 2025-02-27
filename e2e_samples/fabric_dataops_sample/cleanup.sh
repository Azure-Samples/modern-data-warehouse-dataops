#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

source ./.env

# Log all outputs and errors to a log file
log_file="cleanup_${BASE_NAME}_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$log_file")
exec 2>&1

for i in "${!ENVIRONMENT_NAMES[@]}"; do

  if [ "$i" -eq 0 ]; then
    deploy_fabric_items="true"
  else
    deploy_fabric_items="false"
  fi

  ENVIRONMENT_NAME=${ENVIRONMENT_NAMES[$i]} \
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAMES[$i]} \
  TENANT_ID=$TENANT_ID \
  SUBSCRIPTION_ID=$SUBSCRIPTION_ID \
  BASE_NAME=$BASE_NAME \
  APP_CLIENT_ID=$APP_CLIENT_ID \
  APP_CLIENT_SECRET=$APP_CLIENT_SECRET \
  GIT_ORGANIZATION_NAME=$GIT_ORGANIZATION_NAME \
  GIT_PROJECT_NAME=$GIT_PROJECT_NAME \
  GIT_REPOSITORY_NAME=$GIT_REPOSITORY_NAME \
  GIT_BRANCH_NAME=${GIT_BRANCH_NAMES[$i]} \
  FABRIC_WORKSPACE_ADMIN_SG_NAME=$FABRIC_WORKSPACE_ADMIN_SG_NAME \
  EXISTING_FABRIC_CAPACITY_NAME=$EXISTING_FABRIC_CAPACITY_NAME \
  FABRIC_CAPACITY_ADMINS=$FABRIC_CAPACITY_ADMINS \
  DEPLOY_FABRIC_ITEMS=$deploy_fabric_items \
  bash -c "./scripts/cleanup_infrastructure.sh"
done
