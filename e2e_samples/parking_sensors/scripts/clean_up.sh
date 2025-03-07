#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

. ./scripts/init_environment.sh
. ./scripts/verify_prerequisites.sh

###################
# PARAMETERS
#
# RESOURCE_GROUP_NAME_PREFIX
prefix="mdwdops" # CONSTANT - this is prefixes to all resources of the Parking Sensor sample
DEPLOYMENT_ID=${DEPLOYMENT_ID:-}

delete_uc(){
    local PROJECT=$1
    local DEPLOYMENT_ID=$2
    local ENV_NAME=$3

    kv_name="$PROJECT-kv-$ENV_NAME-$DEPLOYMENT_ID"
    if az keyvault show --name "$kv_name" &>/dev/null; then
        databricksHost=$(az keyvault secret show --name "databricksDomain" --vault-name "$kv_name" --query "value" -o tsv)
        log "Databricks Host: $databricksHost"
        databricksToken=$(az keyvault secret show --name "databricksToken" --vault-name "$kv_name" --query "value" -o tsv)
        log "Databricks Token: $databricksToken"
        cat <<EOL > ~/.databrickscfg
[DEFAULT]
host=$databricksHost
token=$databricksToken
EOL

        # Name of the Catalog that needs to be cleaned up
        catalog_name="$PROJECT-$DEPLOYMENT_ID-catalog-$ENV_NAME"
        external_location_data="$PROJECT-data-$DEPLOYMENT_ID-ext-location-$ENV_NAME"
        external_location_catalog="$PROJECT-catalog-$DEPLOYMENT_ID-ext-location-$ENV_NAME"
        storage_credential_name="$PROJECT-$DEPLOYMENT_ID-stg-credential-$ENV_NAME"

        # Main script execution
        if [ -n "$catalog_name" ] && databricks catalogs get $catalog_name > /dev/null 2>&1; then
            schemas=$(databricks schemas list $catalog_name --output JSON | jq -r '.[].name')
            for schema in $schemas; do
                if [[ "$schema" == "information_schema" ]]; then 
                    log "Schema $schema can't be deleted. It will be deleted with the catalog."
                else
                    tables=$(databricks tables list $catalog_name $schema --output JSON | jq -r '.[].name')
                    for table in $tables; do
                    if [[ $table == "" ]]; then
                        log "No tables found in schema $schema."
                    else
                        databricks tables delete "$catalog_name.$schema.$table"
                        log "Table $table in schema $catalog_name.$schema.$table deleted."
                    fi
                    done
                    databricks schemas delete "$catalog_name.$schema"
                    log "Schema $catalog_name.$schema deleted."
                fi
            done
        else
            log "Catalog $catalog_name does not exist."
        fi

        # Check if catalog_name is not empty and delete if it exists
        if [ -n "$catalog_name" ] && databricks catalogs get $catalog_name > /dev/null 2>&1; then
            databricks catalogs delete $catalog_name
            log "Catalog $catalog_name deleted."
        else
            log "Catalog $catalog_name does not exist or is empty."
        fi

        # Check if external_location_data is not empty and delete if it exists
        if [ -n "$external_location_data" ] && databricks external-locations get $external_location_data > /dev/null 2>&1; then
            databricks external-locations delete $external_location_data
            log "External location $external_location_data deleted."
        else
            log "External location $external_location_data does not exist or is empty."
        fi

        # Check if external_location_catalog is not empty and delete if it exists
        if [ -n "$external_location_catalog" ] && databricks external-locations get $external_location_catalog > /dev/null 2>&1; then
            databricks external-locations delete $external_location_catalog
            log "External location $external_location_catalog deleted."
        else
            log "External location $external_location_catalog does not exist or is empty."
        fi

        # Check if storage_credential_name is not empty and delete if it exists
        if [ -n "$storage_credential_name" ] && databricks storage-credentials get $storage_credential_name > /dev/null 2>&1; then
            databricks storage-credentials delete $storage_credential_name
            log "Storage credential $storage_credential_name deleted."
        else
            log "Storage credential $storage_credential_name does not exist or is empty."
        fi
    else
        log "KeyVault $kv_name does not exist."
        return
    fi
}

delete_all(){
    local prefix=$1
    local DEPLOYMENT_ID=${2:-}

    log "!! WARNING: !!" "danger"
    log "THIS SCRIPT WILL DELETE RESOURCES PREFIXED WITH $prefix AND HAVING DEPLOYMENT_ID $DEPLOYMENT_ID!!" "danger"

    log "\nDEVOPS PIPELINES:\n"
    az pipelines list -o tsv --only-show-errors --query "[?contains(name,'$prefix')].name"
    
    log "\nDEVOPS VARIABLE GROUPS:\n"
    az pipelines variable-group list -o tsv --only-show-errors --query "[?contains(name, '$prefix')].name"
    
    log "\nDEVOPS SERVICE CONNECTIONS:\n"
    az devops service-endpoint list -o tsv --only-show-errors --query "[?contains(name, '$prefix')].name"
    
    log "\nENTRA SERVICE PRINCIPALS:\n"
    if [[ -z $DEPLOYMENT_ID ]] 
    then
        az ad sp list -o tsv --show-mine --query "[?contains(appDisplayName,'$prefix')].displayName"
    else
        az ad sp list -o tsv --show-mine --query "[?contains(appDisplayName,'$prefix') && contains(appDisplayName,'$DEPLOYMENT_ID')].displayName"
    fi

    log "\nENTRA APP REGISTRATIONS:\n"
    if [[ -z $DEPLOYMENT_ID ]] 
    then
        az ad app list -o tsv --show-mine --query "[?contains(displayName,'$prefix')].displayName"
    else
        az ad app list -o tsv --show-mine --query "[?contains(displayName,'$prefix') && contains(displayName,'$DEPLOYMENT_ID')].displayName"
    fi

    log "\nUNITY CATALOG OBJECTS:\n"
    if [[ -z $DEPLOYMENT_ID ]] 
    then
        log "In order to delete Unity Catalog, please provide the deployment id [DEPLOYMENT_ID]..."
    else
        for env in "dev" "stg" "prod"
            do
                log "Catalog: $prefix-$DEPLOYMENT_ID-catalog-$env"
                log "External Location: $prefix-data-$DEPLOYMENT_ID-ext-location-$env"
                log "External Location: $prefix-catalog-$DEPLOYMENT_ID-ext-location-$env"
                log "Storage Credential: $prefix-$DEPLOYMENT_ID-stg-credential-$env"
            done
    fi

    log "\nRESOURCE GROUPS:\n"
    if [[ -z $DEPLOYMENT_ID ]] 
    then
        az group list -o tsv --query "[?contains(name,'$prefix') && ! contains(name,'dbw')].name"
    else
        az group list -o tsv --query "[?contains(name,'$prefix-$DEPLOYMENT_ID') && ! contains(name,'dbw')].name"
    fi

    log "\nEND OF SUMMARY\n"

    read -r -p "Do you wish to DELETE above? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            log "Deleting pipelines that start with '$prefix' in name..."
            [[ -n $prefix ]] &&
                az pipelines list -o tsv --query "[?contains(name, '$prefix')].id" |
                xargs -r -I % az pipelines delete --id % --yes

            log "Deleting variable groups that start with '$prefix' in name..."
            [[ -n $prefix ]] &&
                az pipelines variable-group list -o tsv --query "[?contains(name, '$prefix')].id" |
                xargs -r -I % az pipelines variable-group delete --id % --yes

            log "Deleting service connections that start with '$prefix' in name..."
            [[ -n $prefix ]] &&
                 
                sc_ids=($(az devops service-endpoint list --project "$AZDO_PROJECT" --organization "$AZDO_ORGANIZATION_URL" --query "[?contains(name, '$prefix')].id" -o tsv))
                for sc_id in "${sc_ids[@]}"; do
                    log "Processing Service Connection ID: $sc_id"
                    delete_azdo_service_connection_principal $sc_id
                done
                # Important: Giving time to process the cleanup
                wait_for_process 20

                az devops service-endpoint list -o tsv --query "[?contains(name, '$prefix')].id" |
                xargs -r -I % az devops service-endpoint delete --id % --yes
                log "Finished cleaning up Service Connections"

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "In order to delete Unity Catalog, please provide the deployment id [DEPLOYMENT_ID]..."
            else
                for env in "dev" "stg" "prod"
                do
                    delete_uc $prefix $DEPLOYMENT_ID $env
                done
            fi

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "Deleting service principals that contain '$prefix' in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad sp list --query "[?contains(appDisplayName,'$prefix')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad sp delete --id %
            else
                log "Deleting service principals that contain '$prefix' and $DEPLOYMENT_ID in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad sp list --query "[?contains(appDisplayName,'$prefix') && contains(appDisplayName,'$DEPLOYMENT_ID')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad sp delete --id %
            fi

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "Deleting app registrations that contain '$prefix' in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad app list --query "[?contains(displayName,'$prefix')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad app delete --id %
            else
                log "Deleting app registrations that contain '$prefix' and $DEPLOYMENT_ID in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad app list --query "[?contains(displayName,'$prefix') && contains(displayName,'$DEPLOYMENT_ID')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad app delete --id %
            fi

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "Deleting resource groups that contain '$prefix' in name..."
                [[ -n $prefix ]] &&
                    az group list --query "[?contains(name,'$prefix') && ! contains(name,'dbw')].name" -o tsv |
                    xargs -I % az group delete --verbose --name % -y
            else
                log "Deleting resource groups that contain '$prefix-$DEPLOYMENT_ID' in name..."
                [[ -n $prefix ]] &&
                    az group list --query "[?contains(name,'$prefix-$DEPLOYMENT_ID') && ! contains(name,'dbw')].name" -o tsv |
                    xargs -I % az group delete --verbose --name % -y
            fi

            ;;
        *)
            exit
            ;;
    esac

}

if [[ -z "$DEPLOYMENT_ID" ]]
then 
    log "No deployment id [DEPLOYMENT_ID] specified. You will only be able to delete by prefix $prefix..."
    response=3
else
    read -r -p "Do you wish to DELETE by"$'\n'"  1) ONLY BY PREFIX ($prefix)?"$'\n'"  2) PREFIX ($prefix) AND DEPLOYMENT_ID ($DEPLOYMENT_ID)?"$'\n'" Choose 1 or 2: " response
fi

case "$response" in
    1) 
        log "Deleting by prefix..."
        delete_all $prefix
        ;;
    2)
        log "Deleting by deployment id..."
        delete_all $prefix $DEPLOYMENT_ID
        ;;
    3)
        read -r -p "Do you wish to DELETE by prefix $prefix? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) 
                delete_all $prefix
                ;;
            *)
                exit
                ;;
        esac
        ;;
    *)
        log "Invalid choice. Exiting..." "warning"
        exit
        ;;
esac