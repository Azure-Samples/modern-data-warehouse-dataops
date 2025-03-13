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

replace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/$1/$2/g" "$3"
  else
    sed -i "s/$1/$2/g" "$3"
  fi
}

echo "[Info] ############  STARTING AZDO REPOSITORY SETUP  ############"
echo "[Info] ############   CREATING AZDO PIPELINE FILES   ############"

# Azure DeOps (AzDo) pipeline template files
ci_artifacts_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-artifacts.yml"
ci_qa_cleanup_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-qa-cleanup.yml"
ci_qa_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-qa.yml"
cd_dev_pipeline_template="devops/templates/pipelines/azure-pipelines-cd-dev.yml"
cd_stg_and_prod_pipeline_template="devops/templates/pipelines/azure-pipelines-cd-stg_and_prod.yml"

# Azure DevOps (AzDo) pipeline actual files (to be created)
ci_artifacts_pipeline="devops/azure-pipelines-ci-artifacts.yml"
ci_qa_cleanup_pipeline="devops/azure-pipelines-ci-qa-cleanup.yml"
ci_qa_pipeline="devops/azure-pipelines-ci-qa.yml"
cd_dev_pipeline="devops/azure-pipelines-cd-dev.yml"
cd_stg_and_prod_pipeline="devops/azure-pipelines-cd-stg_and_prod.yml"

# Copy the pipeline template files to the actual pipeline files
cp "$ci_artifacts_pipeline_template" "$ci_artifacts_pipeline"
cp "$ci_qa_cleanup_pipeline_template" "$ci_qa_cleanup_pipeline"
cp "$ci_qa_pipeline_template" "$ci_qa_pipeline"
cp "$cd_dev_pipeline_template" "$cd_dev_pipeline"
cp "$cd_stg_and_prod_pipeline_template" "$cd_stg_and_prod_pipeline"

for i in "${!ENVIRONMENT_NAMES[@]}"; do
  environment_name="${ENVIRONMENT_NAMES[$i]}"
  branch_name="${GIT_BRANCH_NAMES[$i]}"
  base_name="${BASE_NAME}"

  echo "[Info] Processing environment '${environment_name}', branch '${branch_name}', and base name '${base_name}'."

  azdo_variable_group_name="vg-${base_name}-${environment_name}"
  azdo_service_connection_name="sc-${base_name}-${environment_name}"
  azdo_git_branch_name="${branch_name}"

  index=$((i+1))
  placeholder_branch_name="<ENV${index}_BRANCH_NAME>"
  placeholder_variable_group_name="<ENV${index}_VARIABLE_GROUP_NAME>"
  placeholder_service_connection_name="<ENV${index}_SERVICE_CONNECTION_NAME>"

  # Replace placeholders in the pipeline files
  replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_artifacts_pipeline"
  replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_artifacts_pipeline"
  replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_artifacts_pipeline"

  replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_qa_cleanup_pipeline"
  replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_qa_cleanup_pipeline"
  replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_qa_cleanup_pipeline"

  replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_qa_pipeline"
  replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_qa_pipeline"
  replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_qa_pipeline"

  replace "$placeholder_branch_name" "$azdo_git_branch_name" "$cd_dev_pipeline"
  replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$cd_dev_pipeline"
  replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$cd_dev_pipeline"
  replace "<BASE_NAME>" "$base_name" "$cd_dev_pipeline"

  replace "$placeholder_branch_name" "$azdo_git_branch_name" "$cd_stg_and_prod_pipeline"
  replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$cd_stg_and_prod_pipeline"
  replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$cd_stg_and_prod_pipeline"
done

echo "[Info] ############    AZDO PIPELINE FILES CREATED   ############"
echo "[Info] ############ COPYING LOCAL FILES TO AZDO REPO ############"
for i in "${!ENVIRONMENT_NAMES[@]}"; do
  branch_name="${GIT_BRANCH_NAMES[$i]}"

  # If the current branch is the first branch, then the base branch is empty
  if ((i > 0)); then
    base_branch_name=${GIT_BRANCH_NAMES[$((i-1))]}
  else
    base_branch_name=""
  fi

  echo "[Info] Processing branch '${branch_name}'."
  python3 ./scripts/setup_azdo_repository.py \
    --organization_name "$GIT_ORGANIZATION_NAME" \
    --project_name "$GIT_PROJECT_NAME" \
    --repository_name "$GIT_REPOSITORY_NAME" \
    --branch_name "${branch_name}" \
    --base_branch_name "${base_branch_name}" \
    --username "$GIT_USERNAME" \
    --token "$GIT_PERSONAL_ACCESS_TOKEN"
done

echo "[Info] ############    FILES COPIED AND COMMITTED    ############"
echo "[Info] ############  AZDO REPOSITORY SETUP COMPLETED ############"
