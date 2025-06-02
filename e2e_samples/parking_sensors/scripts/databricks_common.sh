get_databricks_host () {
  databricks_workspace_info=$(az databricks workspace list \
        --resource-group "${resource_group_name}" \
        --query "[?contains(name, '${PROJECT}')].{name:name, workspaceUrl:workspaceUrl, id:id}" \
        --output json)
  echo https://$(echo "${databricks_workspace_info}" | jq -r '.[0].workspaceUrl')
}

create_databrickscfg_file() {
    databricks_host=$(get_databricks_host)
    if [ -z "$databricks_host" ]; then
        log "Databricks host is empty. Exiting." "Error"
        exit 1
    fi
    #get databricks token from key vault
    databricks_kv_token=$(az keyvault secret show --name databricksToken --vault-name $kv_name --query value -o tsv)
    if [ -z "${databricks_kv_token}" ]; then
        log "Databricks token is empty. Exiting." "Error"
        exit 1
    fi
    cat <<EOL > ~/.databrickscfg
[DEFAULT]
host=${databricks_host}
token=${databricks_kv_token}
EOL
}