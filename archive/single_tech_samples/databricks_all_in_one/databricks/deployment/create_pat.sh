#/bin/bash -e
pat_token_config=$(jq -n -c \
    --arg ls "$PAT_LIFETIME" \
    --arg co "Example Token created by Bicep deployment" \
    '{lifetime_seconds: ($ls|tonumber),
     comment: $co}')

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"
json=$(echo "$pat_token_config" | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/token/create")

echo "$json" >"$AZ_SCRIPTS_OUTPUT_PATH"
