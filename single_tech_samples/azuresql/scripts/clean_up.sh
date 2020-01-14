#!/bin/bash

# Delete pipelines with "azuresql in name"
az pipelines list -o tsv | grep "azuresql-" | awk '{print $4}' | xargs -I % az pipelines delete --id % --yes

# Delete service connections
az devops service-endpoint list -o tsv | grep "mdw-dataops" | awk '{print $3}' | xargs -I % az devops service-endpoint delete --id % --yes