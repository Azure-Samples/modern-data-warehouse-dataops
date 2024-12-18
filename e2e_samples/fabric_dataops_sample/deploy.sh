#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

#. ./scripts/common.sh
. ./scripts/verify_prerequisites.sh "./.env"
#. ./scripts/init_environment.sh

#######################
source ./.env

use_cli () {
  user_principal_type=$(az account show --query user.type -o tsv)
  if [[ $user_principal_type == "user" ]]; then
    return 1
  else
    return 0
  fi
}

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
  bash -c "./scripts/deploy_infrastructure.sh"
done

echo "[Info] ############ Uploading packages to Environment ############"
if [[ use_cli ]]; then
  echo "[Info] Skipped for now as the APIs are not working."
  # python3 ./../scripts/setup_fabric_environment.py --workspace_name "$tf_workspace_name" --environment_name "$tf_environment_name" --bearer_token "$fabric_bearer_token"
else
  echo "[Info] Service Principal login does not support loading environments, skipping."
fi
