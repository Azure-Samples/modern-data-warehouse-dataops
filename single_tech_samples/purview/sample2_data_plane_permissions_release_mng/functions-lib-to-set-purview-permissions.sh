#!/bin/bash

function set-permission() {
    # $1: purview account name
    # $2: object ID of the user or group to add
    # $3: U/G for User or Group
    # $4: permission:
        # "purviewmetadatarole_builtin_collection-administrator" root collection admin: 
        # "purviewmetadatarole_builtin_purview-reader" data reader
        # "purviewmetadatarole_builtin_data-curator" data curator
        # "purviewmetadatarole_builtin_data-source-administrator" data source admin
        # "purviewmetadatarole_builtin_data-share-contributor" data share contributor
        # "purviewmetadatarole_builtin_workflow-administrator" workflow admin

    purview_access_token=$(az account get-access-token --resource https://purview.azure.net/ --query accessToken --output tsv)

    body=$(curl -s -H "Authorization: Bearer $purview_access_token" "https://$1.purview.azure.com/policystore/collections/$1/metadataPolicy?api-version=2021-07-01")
    metadata_policy_id=$(echo "$body" | jq -r '.id')   

    if [ "$3" == "U" ]; then
        body=$(echo "$body" | 
            jq --arg perm "$4" --arg objectid "$2" '(.properties.attributeRules[] | 
                select(.id | contains($perm)) | 
                    .dnfCondition[][] | 
                        select(.attributeName == "principal.microsoft.id") | 
                            .attributeValueIncludedIn) += [$objectid]'
        )
    elif [ "$3" == "G" ]; then
        grp_block_exists=$(echo "$body" | jq --arg perm "$4" '.properties.attributeRules[] | 
                select(.id | contains($perm)) | 
                    .dnfCondition[][] | 
                        select(.attributeName == "principal.microsoft.groups")')
        
        if [[ -z $grp_block_exists ]]; then
            body=$(echo "$body" | 
                jq --arg perm "$4" '(.properties.attributeRules[] | 
                    select(.id | contains($perm)) | 
                        .dnfCondition) += [
                            [
                                {
                                    "fromRule": $perm,
                                    "attributeName": "derived.purview.role",
                                    "attributeValueIncludes": $perm
                                },
                                {
                                    "attributeName": "principal.microsoft.groups",
                                    "attributeValueIncludedIn": []
                                }
                            ]
                        ]'
            )
        fi

        # Add the security group
        body=$(echo "$body" | 
            jq --arg perm "$4" --arg objectid "$2" '(.properties.attributeRules[] | 
                select(.id | contains($perm)) | 
                    .dnfCondition[][] | 
                        select(.attributeName == "principal.microsoft.groups") | 
                            .attributeValueIncludedIn) += [$objectid]'
        )
    else
        echo "Invalid parameter $3, expected U for user or G for group."
        exit 2
    fi

    # WARNING: Concurrent calls may lead to inconsistencies on the Purview permissions.
    curl -H "Authorization: Bearer $purview_access_token" -H "Content-Type: application/json" \
        -d "$body" -X PUT -i -s "https://$1.purview.azure.com/policystore/metadataPolicies/${metadata_policy_id}?api-version=2021-07-01" > /dev/null
}

function reset-permission() {
    # $1: purview account name
    # $2: permission:
        # "purviewmetadatarole_builtin_collection-administrator" root collection admin: 
        # "purviewmetadatarole_builtin_purview-reader" data reader
        # "purviewmetadatarole_builtin_data-curator" data curator
        # "purviewmetadatarole_builtin_data-source-administrator" data source admin
        # "purviewmetadatarole_builtin_data-share-contributor" data share contributor
        # "purviewmetadatarole_builtin_workflow-administrator" workflow admin

    purview_access_token=$(az account get-access-token --resource https://purview.azure.net/ --query accessToken --output tsv)

    body=$(curl -s -H "Authorization: Bearer $purview_access_token" "https://$1.purview.azure.com/policystore/collections/$1/metadataPolicy?api-version=2021-07-01")
    metadata_policy_id=$(echo "$body" | jq -r '.id')

    body=$(echo "$body" | 
        jq --arg perm "$2" '(.properties.attributeRules[] | 
            select(.id | contains($perm)) | 
                .dnfCondition[][] | 
                    select(.attributeName == "principal.microsoft.id") | 
                        .attributeValueIncludedIn) = []'
    )
    
    # Check if group block exists
    grp_block_exists=$(echo "$body" | jq --arg perm "$2" '.properties.attributeRules[] | 
                select(.id | contains($perm)) | 
                    .dnfCondition[][] | 
                        select(.attributeName == "principal.microsoft.groups")')

    if [[ ! -z $grp_block_exists ]]; then
        body=$(echo "$body" | 
            jq --arg perm "$2" '(.properties.attributeRules[] | 
                select(.id | contains($perm)) | 
                    .dnfCondition[][] | 
                        select(.attributeName == "principal.microsoft.groups") | 
                            .attributeValueIncludedIn) = []'
        )
    fi

    curl -H "Authorization: Bearer $purview_access_token" -H "Content-Type: application/json" \
        -d "$body" -X PUT -i -s "https://$1.purview.azure.com/policystore/metadataPolicies/${metadata_policy_id}?api-version=2021-07-01" > /dev/null
}

function set-root-collection-admin() {
    # $1: purview account name
    # $2: object ID of the user or group to add
    # $3: U/G for User or Group

    echo "Setting root collection admin permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_collection-administrator"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_collection-administrator"
    fi
}

function set-data-reader() {
    # $1: purview account name
    # $2: identities string comma separated or empty string for reset
    # $3: U/G for User or Group

    echo "Setting data reader permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_purview-reader"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_purview-reader"
    fi
}

function set-data-curator() {
    # $1: purview account name
    # $2: identities string comma separated or empty string for reset
    # $3: U/G for User or Group

    echo "Setting data curator permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_data-curator"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_data-curator"
    fi
}

function set-data-source-admin() {
    # $1: purview account name
    # $2: identities string comma separated or empty string for reset
    # $3: U/G for User or Group

    echo "Setting data source admin permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_data-source-administrator"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_data-source-administrator"
    fi
}

function set-data-share-contributor() {
    # $1: purview account name
    # $2: identities string comma separated or empty string for reset
    # $3: "override" if you want to re-write permission
    # $3: U/G for User or Group

    echo "Setting data share contributor permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_data-share-contributor"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_data-share-contributor"
    fi
}

function set-workflow-admin() {
    # $1: purview account name
    # $2: identities string comma separated or empty string for reset
    # $3: U/G for User or Group

    echo "Setting wokflow admin permissions"
    if [[ -z $2 ]]; then
        reset-permission "$1" "purviewmetadatarole_builtin_workflow-administrator"
    else
        set-permission "$1" "$2" "$3" "purviewmetadatarole_builtin_workflow-administrator"
    fi
}
