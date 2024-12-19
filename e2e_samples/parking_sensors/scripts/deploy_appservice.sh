export appName=data-simulator-$DEPLOYMENT_ID

arm_output=$(
    az deployment group create \
  --resource-group $resource_group_name \
  --template-file "./infrastructure/modules/appservice.bicep" \
  --parameters appName=$appName \
  --output json
)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed."
    exit 1
fi

az webapp config appsettings set --name $appName --resource-group $resource_group_name --settings WEBSITE_NODE_DEFAULT_VERSION="~16"
az webapp deploy --resource-group $resource_group_name --name $appName --type zip --src-path ./data/data-simulator.zip

export API_BASE_URL="https://$appName.azurewebsites.net"

# rewrite parking_sensors/adf/linkedService/Ls_Http_DataSimulator.json
input_file="./adf/linkedService/Ls_Http_DataSimulator.json"
jq --arg new_url "$API_BASE_URL" '.properties.typeProperties.url = $new_url' "$input_file.template" > "$input_file"

# rewrite parking_sensors/adf/linkedService/Ls_Rest_ParkSensors_01.json
input_file="./adf/linkedService/Ls_Rest_ParkSensors_01.json"
jq --arg new_url "$API_BASE_URL" '.properties.typeProperties.url = $new_url' "$input_file.template" > "$input_file"
