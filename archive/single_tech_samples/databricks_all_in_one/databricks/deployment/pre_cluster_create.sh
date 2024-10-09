#/bin/bash -e
USER_FOLDER=$(pwd)

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Download init script"
mkdir -p init_scripts && cd init_scripts
curl -L \
    -O "https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/main/databricks/init_scripts/capture_log_metrics.sh"
cd $USER_FOLDER

echo "Upload init script to /databricks/init/capture_log_metrics.sh"
curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
    https://${ADB_WORKSPACE_URL}/api/2.0/dbfs/put \
    --form contents=@init_scripts/capture_log_metrics.sh \
    --form path="/databricks/init/capture_log_metrics.sh" \
    --form overwrite=true

echo "Download Sample notebooks"
mkdir -p notebooks && cd notebooks
curl -L \
    -O "https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/00a2978db789d1f1edf63603666d37a1ab72c86f/databricks/notebooks/azure_runner_docs_example.ipynb" \
    -O "https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/00a2978db789d1f1edf63603666d37a1ab72c86f/databricks/notebooks/timezone_test.ipynb"
cd $USER_FOLDER

echo "Upload Sample notebooks"
for notebook in notebooks/*.ipynb; do
    filename=$(basename $notebook)
    echo "Upload sample notebook $notebook to workspace"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${ADB_WORKSPACE_URL}/api/2.0/workspace/import \
        --form contents=@"$notebook" \
        --form path="/Shared/$filename" \
        --form format=JUPYTER \
        --form language=SCALA \
        --form overwrite=true
done

echo "Download Loganalytics jar files"
mkdir -p jars && cd jars
curl -L \
    -O "https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/00a2978db789d1f1edf63603666d37a1ab72c86f/databricks/jars/spark-listeners-loganalytics_3.0.1_2.12-1.0.0.jar" \
    -O "https://raw.githubusercontent.com/lordlinus/databricks-all-in-one-bicep-template/00a2978db789d1f1edf63603666d37a1ab72c86f/databricks/jars/spark-listeners_3.0.1_2.12-1.0.0.jar"
cd $USER_FOLDER

echo "Upload jar files"
for jar_file in jars/*.jar; do
    filename=$(basename $jar_file)
    echo "Upload $jar_file file to DBFS path"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${ADB_WORKSPACE_URL}/api/2.0/dbfs/put \
        --form filedata=@"$jar_file" \
        --form path="/FileStore/jars/$filename" \
        --form overwrite=true
done

# Get ADB log categories
adb_logs_types=$(az monitor diagnostic-settings categories list --resource $ADB_WORKSPACE_ID | jq -c '.value[] | {category: .name, enabled:true}' | jq --slurp .)

# Enable monitoring for all the categories
adb_monitoring=$(az monitor diagnostic-settings create \
    --name sparkmonitor \
    --event-hub $EVENT_HUB_ID \
    --event-hub-rule "RootManageSharedAccessKey" \
    --resource $ADB_WORKSPACE_ID \
    --logs "$adb_logs_types")