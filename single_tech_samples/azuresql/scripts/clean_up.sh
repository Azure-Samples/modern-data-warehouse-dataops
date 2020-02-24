#!/bin/bash

echo "Delete pipelines with 'mdw-dataops-azuresql' in name..."
az pipelines list -o tsv | grep "mdw-dataops-azuresql" | awk '{print $4}' | xargs -I % az pipelines delete --id % --yes

echo "Delete service connections with 'mdw-dataops-azuresql' in name..."
az devops service-endpoint list -o tsv | grep "mdw-dataops-azuresql" | awk '{print $3}' | xargs -I % az devops service-endpoint delete --id % --yes

echo "Delete service principal with 'mdw-dataops-azuresql' in name, created by yourself..."
az ad sp list --query "[?contains(appDisplayName,'mdw-dataops-azuresql')].appId" -o tsv --show-mine | xargs -I % az ad sp delete --id %

echo "Delete resource group with 'mdw-dataops-azuresq' in name..."
az group list --query "[?contains(name,'mdw-dataops-azuresql')].name" -o tsv | xargs -I % az group delete --name % -y --no-wait