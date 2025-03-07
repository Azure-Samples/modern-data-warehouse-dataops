#!/bin/bash

# Usage: clean_up.sh <rg_name>
echo "deleting all deployed resources in the resource group $1"
az resource list --resource-group $1 -o table

echo "deleting resource group $1"
az group delete --name $1 --yes --no-wait

# TODO: Delete security group, network security group, and other resources that are not deleted by deleting the resource group.
