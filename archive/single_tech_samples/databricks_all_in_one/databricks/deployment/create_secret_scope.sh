#/bin/bash -e

# TODO: Create AKV backed secret scope using User assigned managed identity. Currently not supported
# akv_backed='{"resource_id": "'${AKV_ID}'","dns_name": "'${AKV_URI}'"}'
# akv_secret_scope_payload=$(
#     jq -n -c \
#         --arg sc "akv_test" \
#         --arg bak "$akv_backed" \
#         '{
#         scope: $sc,
#         scope_backend_type: "AZURE_KEYVAULT",
#         initial_manage_principal: "users",
#         backend_azure_keyvault: ($bak|fromjson)
#      }'
# )

# Create secret scope backed by ADB
adb_secret_scope_payload=$(
    jq -n -c \
        --arg sc "$ADB_SECRET_SCOPE_NAME" \
        '{
        scope: $sc,
        initial_manage_principal: "users"
     }'
)

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Create ADB secret scope backed by Databricks key vault"
json=$(echo $adb_secret_scope_payload | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/secrets/scopes/create")

function createKey() {
    local keyName=$1
    local secretValue=$2
    json_payload=$(
        jq -n -c \
            --arg sc "$ADB_SECRET_SCOPE_NAME" \
            --arg k "$keyName" \
            --arg v "$secretValue" \
            '{
            scope: $sc,
            key: $k,
            string_value: $v
        }'
    )
    response=$(echo $json_payload | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/secrets/put")
    echo $response

}

createKey "LogAWkspId" "$ADB_LOG_WKSP_ID"
createKey "LogAWkspkey" "$ADB_LOG_WKSP_KEY"
C_ADB_PAT_TOKEN=$(sed -e 's/[\"\\]//g' <<<$ADB_PAT_TOKEN)
createKey "dbPATKey" "$C_ADB_PAT_TOKEN"
createKey "ehKey" "$EVENT_HUB_KEY"
createKey "stgAccessKey" "$STORAGE_ACCESS_KEY"

echo "$json" >"$AZ_SCRIPTS_OUTPUT_PATH"

# tail -f /dev/null