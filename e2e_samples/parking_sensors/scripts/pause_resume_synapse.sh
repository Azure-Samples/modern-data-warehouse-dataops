#!/bin/bash

# Script to Pause or Resume Azure Synapse SQL Pools and Azure SQL Data Warehouse (Dedicated SQL Pools).
# Requires Azure CLI installed and logged in.

set -e

# Parameters
DEPLOYMENT_IDS=()
PROJECT=""
SUBSCRIPTION_ID=""
ENVIRONMENTS=("dev" "stg" "prod")
RESOURCE_GROUPS=()
ACTION="Pause"
DRY_RUN=false

# Function to display usage
usage() {
  echo "Usage: $0 -s SUBSCRIPTION_ID [-d DEPLOYMENT_IDS -p PROJECT -e ENVIRONMENTS] [-r RESOURCE_GROUPS] [-a ACTION] [--dry-run]"
  echo "    -s | --subscription-id    Azure Subscription ID (required)."
  echo "    -d | --deployment-ids     Deployment IDs (comma-separated, required if --resource-groups is not specified)."
  echo "    -p | --project            Project name (required if --resource-groups is not specified)."
  echo "    -e | --environments       Environments (comma-separated, default: dev,stg,prod)."
  echo "    -r | --resource-groups    Resource groups (comma-separated)."
  echo "    -a | --action             Action to perform: Pause or Resume (default: Pause)."
  echo "    --dry-run                Perform a dry run without executing actions."
  exit 1
}

# Log functions
log_info() {
  echo -e "$(tput setaf 2)INFO:$(tput sgr0) $1"
}

log_warning() {
  echo -e "$(tput setaf 3)WARNING:$(tput sgr0) $1"
}

log_error() {
  echo -e "$(tput setaf 1)ERROR:$(tput sgr0) $1"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -s|--subscription-id) SUBSCRIPTION_ID="$2"; shift 2;;
    -d|--deployment-ids) IFS="," read -r -a DEPLOYMENT_IDS <<< "$2"; shift 2;;
    -p|--project) PROJECT="$2"; shift 2;;
    -e|--environments) IFS="," read -r -a ENVIRONMENTS <<< "$2"; shift 2;;
    -r|--resource-groups) IFS="," read -r -a RESOURCE_GROUPS <<< "$2"; shift 2;;
    -a|--action) ACTION="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    *) usage;;
  esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  log_error "SUBSCRIPTION_ID is required."
  usage
fi

if [[ ${#RESOURCE_GROUPS[@]} -eq 0 ]]; then
  if [[ ${#DEPLOYMENT_IDS[@]} -eq 0 || -z "$PROJECT" ]]; then
    log_error "DEPLOYMENT_IDS and PROJECT are required if --resource-groups is not specified."
    usage
  fi
fi

# Generate or override resource group names
if [[ ${#RESOURCE_GROUPS[@]} -gt 0 ]]; then
  RESOURCE_GROUPS=(${RESOURCE_GROUPS[@]})
else
  for env in "${ENVIRONMENTS[@]}"; do
    for deployment_id in "${DEPLOYMENT_IDS[@]}"; do
      RESOURCE_GROUPS+=("${PROJECT}-${deployment_id}-dbw-${env}-rg")
      RESOURCE_GROUPS+=("${PROJECT}-${deployment_id}-${env}-rg")
    done
  done
fi

log_info "Using Resource Groups: ${RESOURCE_GROUPS[*]}"

# Set Azure subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Function to process Synapse SQL Pools
process_synapse_sql_pool() {
  local resource_group="$1"
  local action="$2"

  # Retrieve Synapse Workspaces
  workspaces=$(az synapse workspace list --resource-group "$resource_group" --query "[].name" -o tsv 2>/dev/null)
  if [[ -z "$workspaces" ]]; then
    log_warning "No Synapse Workspaces found in Resource Group: $resource_group"
    return
  fi

  for workspace in $workspaces; do
    log_info "  Checking Workspace: $workspace"

    sql_pools=$(az synapse sql pool list --workspace-name "$workspace" --resource-group "$resource_group" --query "[].{name:name,status:status}" -o tsv)
    if [[ -z "$sql_pools" ]]; then
      log_warning "    No SQL Pools found in Workspace: $workspace"
      continue
    fi

    while IFS=$'\t' read -r pool_name pool_status; do
      log_info "    SQL Pool: $pool_name (Status: $pool_status)"

      if [[ "$DRY_RUN" == true ]]; then
        log_info "      Dry Run: Would have ${action}d Synapse SQL Pool: $pool_name"
      else
        if [[ "$action" == "Pause" && "$pool_status" == "Online" ]]; then
          log_info "      Pausing Synapse SQL Pool: $pool_name"
          az synapse sql pool pause --name "$pool_name" --workspace-name "$workspace" --resource-group "$resource_group"
          log_info "      Successfully paused Synapse SQL Pool: $pool_name"
        elif [[ "$action" == "Resume" && "$pool_status" == "Paused" ]]; then
          log_info "      Resuming Synapse SQL Pool: $pool_name"
          az synapse sql pool resume --name "$pool_name" --workspace-name "$workspace" --resource-group "$resource_group"
          log_info "      Successfully resumed Synapse SQL Pool: $pool_name"
        else
          log_info "      Synapse SQL Pool: $pool_name is already in the desired state."
        fi
      fi
    done <<< "$sql_pools"
  done
}

# Function to process Azure SQL Data Warehouse (Dedicated SQL Pools)
process_sql_database() {
  local resource_group="$1"
  local action="$2"

  # Retrieve SQL Servers
  sql_servers=$(az sql server list --resource-group "$resource_group" --query "[].name" -o tsv 2>/dev/null)
  if [[ -z "$sql_servers" ]]; then
    log_warning "No SQL Servers found in Resource Group: $resource_group"
    return
  fi

  for server in $sql_servers; do
    log_info "  Checking SQL Server: $server"

    sql_dws=$(az sql dw list --server "$server" --resource-group "$resource_group" --query "[].{name:name,status:status}" -o tsv)
    if [[ -z "$sql_dws" ]]; then
      log_warning "    No Dedicated SQL Pools found on Server: $server"
      continue
    fi

    while IFS=$'\t' read -r dw_name dw_status; do
      log_info "    Dedicated SQL Pool: $dw_name (Status: $dw_status)"

      if [[ "$DRY_RUN" == true ]]; then
        log_info "      Dry Run: Would have ${action}d Dedicated SQL Pool: $dw_name"
      else
        if [[ "$action" == "Pause" && "$dw_status" == "Online" ]]; then
          log_info "      Pausing Dedicated SQL Pool: $dw_name"
          az sql dw pause --name "$dw_name" --server "$server" --resource-group "$resource_group"
          log_info "      Successfully paused Dedicated SQL Pool: $dw_name"
        elif [[ "$action" == "Resume" && "$dw_status" == "Paused" ]]; then
          log_info "      Resuming Dedicated SQL Pool: $dw_name"
          az sql dw resume --name "$dw_name" --server "$server" --resource-group "$resource_group"
          log_info "      Successfully resumed Dedicated SQL Pool: $dw_name"
        else
          log_info "      Dedicated SQL Pool: $dw_name is already in the desired state."
        fi
      fi
    done <<< "$sql_dws"
  done
}

# Process each resource group
for resource_group in "${RESOURCE_GROUPS[@]}"; do
  if ! az group show --name "$resource_group" &>/dev/null; then
    log_error "Resource Group [$resource_group] does not exist. Skipping."
    continue
  fi

  log_info "Processing Resource Group: $resource_group"
  echo "----------------------------------------"

  # Process Synapse SQL Pools
  process_synapse_sql_pool "$resource_group" "$ACTION"

  # Process Azure SQL Data Warehouse (Dedicated SQL Pools)
  process_sql_database "$resource_group" "$ACTION"
done