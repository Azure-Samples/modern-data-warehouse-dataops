#!/bin/bash

echo "Delete pipelines with 'mdw-dataops-' in name..."
az pipelines list -o tsv | grep "mdw-dataops-" | awk '{print $4}' | xargs -I % az pipelines delete --id % --yes

echo "Delete service connections..."
az devops service-endpoint list -o tsv | grep "mdw-dataops" | awk '{print $3}' | xargs -I % az devops service-endpoint delete --id % --yes

echo "Delete service principal..."
az ad sp list --query "[?contains(appDisplayName,'mdw-dataops')].appId" -o tsv --show-mine | xargs -I % az ad sp delete --id %