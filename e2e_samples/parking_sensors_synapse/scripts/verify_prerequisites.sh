#!/bin/bash

# Check if required utilities are installed
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed. See https://stedolan.github.io/jq/.  Aborting."; exit 1; }
command -v az >/dev/null 2>&1 || { echo >&2 "I require azure cli but it's not installed. See https://bit.ly/2Gc8IsS. Aborting."; exit 1; }
# command -v makepasswd >/dev/null 2>&1 || { echo >&2 "I require makepasswd. See https://bit.ly/3GneVxD. Aborting."; exit 1; }

# Check if user is logged in
[[ -n $(az account show 2> /dev/null) ]] || { echo "Please login via the Azure CLI: "; az login; }

# Check if az cli required extensions are installed
az extension list -o tsv | grep application-insights >/dev/null || { echo >&2 "I required az cli extension: application-insights. Aborting."; exit 1; }
az extension list -o tsv | grep azure-devops >/dev/null || { echo >&2 "I required az cli extension: azure-devops. Aborting."; exit 1; }