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

# Azure DeOps (AzDo) pipeline files
ci_artifacts_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-artifacts.yml"
ci_qa_cleanup_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-qa-cleanup.yml"
ci_qa_pipeline_template="devops/templates/pipelines/azure-pipelines-ci-qa.yml"

ci_artifacts_pipeline="devops/azure-pipelines-ci-artifacts.yml"
ci_qa_cleanup_pipeline="devops/azure-pipelines-ci-qa-cleanup.yml"
ci_qa_pipeline="devops/azure-pipelines-ci-qa.yml"

echo "[Info] ############ STARTING AZDO REPOSITORY SETUP ############"

replace() {
  echo "[Info] Replacing '$1' with '$2' in file '$3' and saving as '$4'."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/$1/$2/g" "$3" > "$4"
  else
    sed -i "s/$1/$2/g" "$3" > "$4"
  fi
}

for i in "${!ENVIRONMENT_NAMES[@]}"; do
  environment_name="${ENVIRONMENT_NAMES[$i]}"
  branch_name="${GIT_BRANCH_NAMES[$i]}"
  base_name="${BASE_NAME}"

  echo "[Info] Processing environment '${environment_name}', branch '${branch_name}', and base name '${base_name}'."

  azdo_variable_group_name="vg-${base_name}-${environment_name}"
  azdo_service_connection_name="sc-${base_name}-${environment_name}"
  azdo_git_branch_name="${branch_name}"

  upper_environment_name=$(echo "$environment_name" | tr '[:lower:]' '[:upper:]')
  placeholder_branch_name="<${upper_environment_name}_BRANCH_NAME>"
  placeholder_variable_group_name="<${upper_environment_name}_VARIABLE_GROUP_NAME>"
  placeholder_service_connection_name="<${upper_environment_name}_SERVICE_CONNECTION_NAME>"

  echo "[Info] Replacing placeholders in the pipeline template file."
  echo "placeholder_branch_name: ${placeholder_branch_name}"
  echo "placeholder_variable_group_name: ${placeholder_variable_group_name}"
  echo "placeholder_service_connection_name: ${placeholder_service_connection_name}"

  echo "azdo_git_branch_name: ${azdo_git_branch_name}"
  echo "azdo_variable_group_name: ${azdo_variable_group_name}"
  echo "azdo_service_connection_name: ${azdo_service_connection_name}"

  echo "s/${placeholder_variable_group_name}/${azdo_variable_group_name}/g"

  # Replace placeholders in the pipeline files
  if [[ "$OSTYPE" == "darwin"* ]]; then
    replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_artifacts_pipeline_template" "$ci_artifacts_pipeline"
    replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_artifacts_pipeline_template" "$ci_artifacts_pipeline"
    replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_artifacts_pipeline_template" "$ci_artifacts_pipeline"

    replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_qa_cleanup_pipeline_template" "$ci_qa_cleanup_pipeline"
    replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_qa_cleanup_pipeline_template" "$ci_qa_cleanup_pipeline"
    replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_qa_cleanup_pipeline_template" "$ci_qa_cleanup_pipeline"

    replace "$placeholder_branch_name" "$azdo_git_branch_name" "$ci_qa_pipeline_template" "$ci_qa_pipeline"
    replace "$placeholder_variable_group_name" "$azdo_variable_group_name" "$ci_qa_pipeline_template" "$ci_qa_pipeline"
    replace "$placeholder_service_connection_name" "$azdo_service_connection_name" "$ci_qa_pipeline_template" "$ci_qa_pipeline"
  fi
done

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

echo "[Info] ############ AZDO REPOSITORY SETUP COMPLETED ############"
