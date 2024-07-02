#!/bin/bash
# Set your variables
organization_url="<AZURE_DEVOPS_ORGANIZATION_URL>"
tenant_id="<TENANT_ID>"
project="<AZURE_DEVOPS_PROJECT_NAME>"
variable_group_name="<AZURE_DEVOPS_VARIABLE_GROUP_NAME>"
variable_name="token"

# Do "az login" to get the access token
az config set core.login_experience_v2=off
az login --tenant ${tenant_id}
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
variable_value=$(az pipelines variable-group variable list \
                    --org "$organization_url" \
                    --project "$project" \
                    --group-id "$variable_group_id" \
                    --query "$variable_name.value" \
                    -o tsv)

# Check if the variable exists
if [ -z "$variable_value" ]; then
  echo "[I] Variable '$variable_name' not found in the variable group '$variable_group_name', creating the variable."
  az pipelines variable-group variable create \
    --org "$organization_url" \
    --project "$project" \
    --group-id "$variable_group_id" \
    --secret true \
    --name "$variable_name" \
    --value "$token"
else
  echo "[I] Variable '$variable_name' found in the variable group '$variable_group_name', updating the variable."
  az pipelines variable-group variable update \
    --org "$organization_url" \
    --project "$project" \
    --group-id "$variable_group_id" \
    --secret true \
    --name "$variable_name" \
    --value "$token"
fi

echo "[I] Variable '$variable_name' created/updated successfully."
