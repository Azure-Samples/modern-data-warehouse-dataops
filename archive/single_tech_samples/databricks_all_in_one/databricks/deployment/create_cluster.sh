#/bin/bash -e

# Databricks cluster config variables
DATABRICKS_SPARK_CONF='{
        "spark.databricks.delta.preview.enabled": "true",
        "spark.eventLog.unknownRecord.maxSize":"16m"
    }'
DATABRICKS_INIT_CONFIG='{
        "dbfs": {
            "destination": "dbfs:/databricks/init/capture_log_metrics.sh"
        }
    }'
DATABRICKS_ENV_VARS='{
        "LOG_ANALYTICS_WORKSPACE_ID": "{{secrets/'$ADB_SECRET_SCOPE_NAME'/LogAWkspId}}",
        "LOG_ANALYTICS_WORKSPACE_KEY": "{{secrets/'$ADB_SECRET_SCOPE_NAME'/LogAWkspkey}}"
    }'
DATABRICKS_CLUSTER_LOG='{
    "dbfs": {
      "destination": "dbfs:/logs"
    }
}'

# Databricks Auth headers
adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

# Create Auth header for Databricks
authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Create Cluster"

CLUSTER_CREATE_JSON_STRING=$(jq -n -c \
    --arg cn "$DATABRICKS_CLUSTER_NAME" \
    --arg sv "$DATABRICKS_SPARK_VERSION" \
    --arg nt "$DATABRICKS_NODE_TYPE" \
    --arg nw "$DATABRICKS_NUM_WORKERS" \
    --arg spc "$DATABRICKS_SPARK_CONF" \
    --arg at "$DATABRICKS_AUTO_TERMINATE_MINUTES" \
    --arg is "$DATABRICKS_INIT_CONFIG" \
    --arg ev "$DATABRICKS_ENV_VARS" \
    --arg cl "$DATABRICKS_CLUSTER_LOG" \
    '{cluster_name: $cn,
                    idempotency_token: $cn,
                    spark_version: $sv,
                    node_type_id: $nt,
                    num_workers: ($nw|tonumber),
                    autotermination_minutes: ($at|tonumber),
                    spark_conf: ($spc|fromjson),
                    init_scripts: ($is|fromjson),
                    spark_env_vars: ($ev|fromjson),
                    cluster_log_conf: ($cl|fromjson)
                    }')

json=$(echo $CLUSTER_CREATE_JSON_STRING | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/clusters/create")
echo "$json" >$AZ_SCRIPTS_OUTPUT_PATH
