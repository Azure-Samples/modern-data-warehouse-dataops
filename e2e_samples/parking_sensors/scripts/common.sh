#!/bin/bash

# Source enviroment variables
. .devcontainer/.env

# Helper functions
random_str() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1 | tr '[:upper:]' '[:lower:]'
    return 0
}

print_style () {
    case "$2" in
        "info")
            COLOR="96m"
            ;;
        "debug")
            COLOR="96m"
            ;;
        "success")
            COLOR="92m"
            ;;
        "error")
            COLOR="91m"
            ;;
        "warning")
            COLOR="93m"
            ;;
        "danger")
            COLOR="91m"
            ;;
        "action")
            COLOR="32m"
            ;;
        *)
            COLOR="0m"
            ;;
    esac

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"
    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
}

log() {
    # This function takes a string as an argument and prints it to the console to stderr
    # if a second argument is provided, it will be used as the style of the message
    # Usage: log "message" "style"
    # Example: log "Hello, World!" "info"
    local message=$1
    local style=${2:-}

    if [[ -z "$style" ]]; then
        echo -e "$(print_style "$message" "default")" >&2
    else
        echo -e "$(print_style "$message" "$style")" >&2
    fi
}

deployed_stages_contains() {
    local value=$1  # Takes the first argument as the value to search for
        
    for item in "${deployed_stages[@]}"; do  # Loops through each item in deployed_stages
        if [[ "$item" == "$value" ]]; then  # Compares the item with the search value
            return 0  # Returns success (true) if found
        fi
    done
    return 1  # Returns failure (false) if not found
}

deploy_success() {
    # write a value to a deploystate.env file
    # Usage: deploy_success "last_deploy"
    # Example: deploy_success "build_dependencies"
    local value=$1
    local file_name="deploystate.env"
    local file_path="./$file_name"
    
    # Create file if it doesn't exist
    if [[ ! -f "${file_path}" ]]; then
        touch "${file_path}"
        # Initialize empty array in the file
        echo "deployed_stages=()" > "${file_path}"
    fi
    
    # Source the file to get the current array
    . "${file_path}"
    
    # Add new value to the array - fixing the syntax
    deployed_stages+=("$value")
    
    # Write updated array back to the file
    echo "deployed_stages=(${deployed_stages[*]})" > "${file_path}"
    
    log "Successfully recorded: $value" "success"
}

# Function to give time for the portal to process the cleanup
wait_for_process() {
    local seconds=${1:-15}
    log "Giving the portal $seconds seconds to process the information..." "info"
    sleep "$seconds"
}

delete_azdo_service_connection_principal(){
    # This function deletes the Service Principal associated with the provided AzDO Service Connection
    local sc_id=$1
    local spnAppObjId=$(az devops service-endpoint show --id "$sc_id" --org "$AZDO_ORGANIZATION_URL" -p "$AZDO_PROJECT" --query "data.appObjectId" --output tsv)
    if [ -z "$spnAppObjId" ]; then
        log "Service Principal Object ID not found for Service Connection ID: $sc_id. Skipping Service Principal cleanup." "info"
        return
    fi
    log "Attempting to delete Service Principal." "info"
    az ad app delete --id "$spnAppObjId" &&
        log "Deleted Service Principal: $spnAppObjId" "info" || 
        log "Failed to delete Service Principal: $spnAppObjId" "info"
}
