#!/bin/bash

#############################
##    Utility functions
#############################
print_style () {
    case "$2" in
        "info")
            COLOR="96m"
            ;;
        "success")
            COLOR="92m"
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

# Function to make REST API calls to Fabric API
rest_call(){
    local method=$1
    local uri=$2
    local query=${3:-}
    local output=${4:-"json"}
    local body=${5:-}

    if [ -z "$query" ] && [ -z "$body" ]; then
        az rest --method $method --uri "$FABRIC_API_BASEURL/$uri" --headers "Authorization=Bearer $FABRIC_USER_TOKEN" --output $output
        return
    fi

    if [ -n "$query" ] && [ -z "$body" ]; then
        az rest --method $method --uri "$FABRIC_API_BASEURL/$uri" --headers "Authorization=Bearer $FABRIC_USER_TOKEN" --query "$query" --output $output
        return
    fi

    if [ -z "$query" ] && [ -n "$body" ]; then
        az rest --method $method --uri "$FABRIC_API_BASEURL/$uri" --headers "Authorization=Bearer $FABRIC_USER_TOKEN" --output $output --body "$body"
    fi

    if [ -n "$query" ] && [ -n "$body" ]; then
        az rest --method $method --uri "$FABRIC_API_BASEURL/$uri" --headers "Authorization=Bearer $FABRIC_USER_TOKEN" --query "$query" --output $output --body "$body"
        return
    fi

}

function is_token_expired {
    # Ensure the token is set
    if [ -z "$FABRIC_USER_TOKEN" ]; then
        log "No FABRIC_USER_TOKEN set."
        echo 1
        return
    fi

    # Extract JWT payload (assumes token format: header.payload.signature)
    payload=$(echo "$FABRIC_USER_TOKEN" | cut -d '.' -f2 | sed 's/-/+/g; s/_/\//g;')
    # Add missing padding if needed
    mod4=$(( ${#payload} % 4 ))
    if [ $mod4 -ne 0 ]; then
        payload="${payload}$(printf '%0.s=' $(seq 1 $((4 - mod4))))"
    fi

    # Decode payload and extract the expiration field using jq
    exp=$(echo "$payload" | base64 -d 2>/dev/null | jq -r '.exp')
    if [ -z "$exp" ]; then
        log "Unable to parse token expiration."
        echo 1
        return
    fi

    # Compare expiration with current time
    current=$(date +%s)
    if [ "$current" -ge "$exp" ]; then
        # Token is expired
        echo 1
    else
        # Token is not expired
        echo 0
    fi
}

