#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

source ./.env

# Log all outputs and errors to a log file
log_file="setup_azdo_repo_${BASE_NAME}_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$log_file")
exec 2>&1

echo "[Info] ############ STARTING AZDO REPOSITORY SETUP ############"

for i in "${!ENVIRONMENT_NAMES[@]}"; do
  branch_name="${GIT_BRANCH_NAMES[$i]}"
  echo "[Info] Processing branch '${branch_name}' for environment '${ENVIRONMENT_NAMES[$i]}'."
  python3 ./scripts/setup_azdo_repository.py \
    --organization_name "$GIT_ORGANIZATION_NAME" \
    --project_name "$GIT_PROJECT_NAME" \
    --repository_name "$GIT_REPOSITORY_NAME" \
    --branch_name "${branch_name}" \
    --directory_name "$GIT_DIRECTORY_NAME" \
    --username "$GIT_USERNAME" \
    --token "$GIT_PERSONAL_ACCESS_TOKEN"
done

echo "[Info] ############ AZDO REPOSITORY SETUP COMPLETED ############"
