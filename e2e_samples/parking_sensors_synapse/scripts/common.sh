#!/bin/bash

# Globals and constants
export TIMESTAMP=$(date +%s)
export RED='\033[0;31m'
export ORANGE='\033[0;33m'
export NC='\033[0m'

# Helper functions
random_str() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1 | tr '[:upper:]' '[:lower:]'
    return 0
}

print_style () {

    if [ "$2" == "info" ] ; then
        COLOR="96m";
    elif [ "$2" == "success" ] ; then
        COLOR="92m";
    elif [ "$2" == "warning" ] ; then
        COLOR="93m";
    elif [ "$2" == "danger" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR" "$1";
}


# There is a delay between creating a service principal and when it is ready for use.
# This helper function to blocks till Service Principal is ready for use.
# Usage: wait_service_principal_creation <SERVICE_PRINCIPAL_APP_ID>
wait_service_principal_creation () {
    local sp_app_id=$1
    until az ad sp list --show-mine --query "[].appId" -o tsv | grep "$sp_app_id"
    do
        echo "waiting for sp to create..."
        sleep 10s
    done
}