#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.

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
                az devops service-endpoint list -o tsv --query "[?contains(name, '$prefix')].id" |
                xargs -r -I % az devops service-endpoint delete --id % --yes

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "Deleting service principal that contain '$prefix' in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad sp list --query "[?contains(appDisplayName,'$prefix')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad sp delete --id %
            else
                log "Deleting service principal that contain '$prefix' and $DEPLOYMENT_ID in name, created by yourself..."
                [[ -n $prefix ]] &&
                    az ad sp list --query "[?contains(appDisplayName,'$prefix') && contains(appDisplayName,'$DEPLOYMENT_ID')].appId" -o tsv --show-mine | 
                    xargs -r -I % az ad sp delete --id %
            fi

            if [[ -z $DEPLOYMENT_ID ]]
            then
                log "Deleting resource groups that comtain '$prefix' in name..."
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
