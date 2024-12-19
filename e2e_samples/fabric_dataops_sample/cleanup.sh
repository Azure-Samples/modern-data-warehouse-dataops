#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

#. ./scripts/common.sh
#. ./scripts/verify_prerequisites.sh
#. ./scripts/init_environment.sh

#######################
source ./.env

# Log all outputs and errors to a log file
log_file="cleanup_${BASE_NAME}_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$log_file")
exec 2>&1

for env_name in dev; do
  ENVIRONMENT_NAME=$env_name \
  TENANT_ID=$TENANT_ID \
  RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME \
  BASE_NAME=$BASE_NAME \
  APP_CLIENT_ID=$APP_CLIENT_ID \
  APP_CLIENT_SECRET=$APP_CLIENT_SECRET \
  GIT_ORGANIZATION_NAME=$GIT_ORGANIZATION_NAME \
  GIT_PROJECT_NAME=$GIT_PROJECT_NAME \
  GIT_REPOSITORY_NAME=$GIT_REPOSITORY_NAME \
  GIT_BRANCH_NAME=$GIT_BRANCH_NAME \
  FABRIC_WORKSPACE_ADMIN_SG_NAME=$FABRIC_WORKSPACE_ADMIN_SG_NAME \
  EXISTING_FABRIC_CAPACITY_NAME=$EXISTING_FABRIC_CAPACITY_NAME \
  FABRIC_CAPACITY_ADMINS=$FABRIC_CAPACITY_ADMINS \
  ADLS_GEN2_CONNECTION_ID=$ADLS_GEN2_CONNECTION_ID \
  bash -c "./scripts/cleanup_infrastructure.sh"
done
