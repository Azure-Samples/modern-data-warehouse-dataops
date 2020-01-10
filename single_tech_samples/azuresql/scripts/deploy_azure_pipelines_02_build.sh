#!/bin/bash

. ./scripts/common.sh


###############
# Deploy Pipelines: build

pipeline_name=azuresql-02-build
echo "Creating Pipeline: $pipeline_name in Azure DevOps"
az pipelines create \
    --name "$pipeline_name" \
    --description 'This pipelines build the DACPAC and publishes it as a Build Artifact' \
    --repository "$GITHUB_REPO_URL" \
    --branch master \
    --yaml-path 'single_tech_samples/azuresql/pipelines/azure-pipelines-02-build.yml' \
    --service-connection "$GITHUB_SERVICE_CONNECTION_ID"

