#!/bin/bash
# Set your variables
# Refer to the Readme on how to get and set your variables
organization_url="<AZURE_DEVOPS_ORGANIZATION_URL>"
tenant_id="<TENANT_ID>"
project="<AZURE_DEVOPS_PROJECT_NAME>"
variable_group_name="<AZURE_DEVOPS_VARIABLE_GROUP_NAME>"
variable_name="token"

# Check if user is logged in
# If user is not logged in then abort and guide them to look at the Readme file
[[ -n $(az account show 2> /dev/null) ]] || { echo "Please login via the Azure CLI and restart the deployment. Check the prerequisites in the Readme. Aborting."; exit 1; }

# Follow the instructions in the Readme on how to do "az login" to get the access token
# The subscription should already be logged in and thus you can get the access token
token=$(az account get-access-token \
          --resource "https://login.microsoftonline.com/${tenant_id}" \
          --query accessToken \
          --scope "https://analysis.windows.net/powerbi/api/.default" \
          -o tsv)

# Check if we got the access token
if [ -z "$token" ]; then
  echo "[E] Failed to get the access token."
  exit 1
fi

# Get the variable group ID
variable_group_id=$(az pipelines variable-group list \
                      --org "$organization_url" \
                      --project "$project" \
                      --query "[?name=='$variable_group_name'].id" \
                      -o tsv)

# Check if the variable group exists
if [ -z "$variable_group_id" ]; then
  echo "[E] Variable group '$variable_group_name' not found."
  exit 1
fi

# Check if the variable exists
variable_exists=$(az pipelines variable-group variable list \
                    --org "$organization_url" \
                    --project "$project" \
                    --group-id "$variable_group_id" \
                    --query "contains(keys(@), '$variable_name')" \
                    -o tsv)

# Check if the variable exists
if [ "$variable_exists" == "true" ]; then
  echo "[I] Variable '$variable_name' found in the variable group '$variable_group_name', updating the variable."
  az pipelines variable-group variable update \
    --org "$organization_url" \
    --project "$project" \
    --group-id "$variable_group_id" \
    --secret true \
    --name "$variable_name" \
    --value "$token"
else
  echo "[I] Variable '$variable_name' not found in the variable group '$variable_group_name', creating the variable."
  az pipelines variable-group variable create \
    --org "$organization_url" \
    --project "$project" \
    --group-id "$variable_group_id" \
    --secret true \
    --name "$variable_name" \
    --value "$token"
fi

echo "[I] Variable '$variable_name' created/updated successfully."
