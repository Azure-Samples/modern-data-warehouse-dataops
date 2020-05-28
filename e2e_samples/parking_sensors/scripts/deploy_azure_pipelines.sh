AZURE_SUBSCRIPTION_ID
RESOURCE_GROUP_NAME
DEPLOYMENT_ID

###############
# Setup Azure service connection

# Create Service Account
az_sp_name=mdwdo-azsql-${DEPLOYMENT_ID}-sp
echo "Creating service principal: $az_sp_name for azure service connection"
az_sp=$(az ad sp create-for-rbac \
    --role contributor \
    --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME \
    --name $az_sp_name \
    --output json)
export SERVICE_PRINCIPAL_ID=$(echo $az_sp | jq -r '.appId')
az_sp_tenant_id=$(echo $az_sp | jq -r '.tenant')

#tags don't seem to work right on service principals at the moment.
az ad sp update --id $SERVICE_PRINCIPAL_ID --add tags "source=mdwdo-azsql"
az ad sp update --id $SERVICE_PRINCIPAL_ID --add tags "deployment=$DEPLOYMENT_ID"

# Create Azure Service connection in Azure DevOps
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$(echo $az_sp | jq -r '.password')
echo "Creating Azure service connection Azure DevOps"
az devops service-endpoint azurerm create \
    --name "mdwdo-azsql" \
    --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" \
    --azure-rm-subscription-id "$AZURE_SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$az_sub_name" \
    --azure-rm-tenant-id "$az_sp_tenant_id"


###############
# Setup Github service connection

export AZURE_DEVOPS_EXT_GITHUB_PAT=$GITHUB_PAT_TOKEN
echo "Creating Github service connection in Azure DevOps"
export GITHUB_SERVICE_CONNECTION_ID=$(az devops service-endpoint github create \
    --name "mdwdo-azsql-github" \
    --github-url "$GITHUB_REPO_URL" \
    --output json | jq -r '.id')