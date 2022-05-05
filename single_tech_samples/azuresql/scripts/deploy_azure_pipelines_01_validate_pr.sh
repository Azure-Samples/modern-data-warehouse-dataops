#!/bin/bash

. ./scripts/common.sh


###############
# Deploy Pipelines: validate pr

pipeline_name=mdwdo-azsql-${DEPLOYMENT_ID}-azuresql-01-validate-pr
echo "Creating Pipeline: $pipeline_name in Azure DevOps"
az pipelines create \
    --name "$pipeline_name" \
    --description 'This pipelines validates pull requests to BRANCH_NAME' \
    --repository "$GITHUB_REPO_URL" \
    --branch "$BRANCH_NAME" \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-01-validate-pr.yml' \
    --service-connection "$GITHUB_SERVICE_CONNECTION_ID"
