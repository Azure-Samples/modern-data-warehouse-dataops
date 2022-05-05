#!/bin/bash

echo "Delete pipelines with 'mdwdo-azsql' in name..."
az pipelines list -o tsv | grep "mdwdo-azsql" | awk '{print $4}' | xargs -I % az pipelines delete --id % --yes

echo "Delete service connections with 'mdwdo-azsql' in name..."
az devops service-endpoint list -o tsv | grep "mdwdo-azsql" | awk '{print $3}' | xargs -I % az devops service-endpoint delete --id % --yes

echo "Delete service principal with 'mdwdo-azsql' in name, created by yourself..."
az ad sp list --query "[?contains(appDisplayName,'mdwdo-azsql')].appId" -o tsv --show-mine | xargs -I % az ad sp delete --id %

echo "Delete resource group with 'mdw-dataops-azuresq' in name..."
az group list --query "[?contains(name,'mdwdo-azsql')].name" -o tsv | xargs -I % az group delete --name % -y --no-wait