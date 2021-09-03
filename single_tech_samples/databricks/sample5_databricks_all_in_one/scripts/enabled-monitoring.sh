#!/usr/bin/env bash

# Enabled Log Analytics monitoring for ADB workspace
# Get ADB log categories
adb_logs_types=$(az monitor diagnostic-settings categories list --resource $ADB_WORKSPACE_ID | jq -c '.value[] | {category: .name, enabled:true}' | jq --slurp .)

# Enable monitoring for all the categories
adb_monitoring=$(az monitor diagnostic-settings create \
    --name sparkmonitor \
    --event-hub $EVENT_HUB_ID \
    --event-hub-rule "RootManageSharedAccessKey" \
    --resource $ADB_WORKSPACE_ID \
    --logs "$adb_logs_types")
