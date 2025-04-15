#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

build_ddotransform_wheel() {
    # Build the WHL package
    log "Building the WHL package...", "info"
    pushd ./src/ddo_transform
    
    mkdir -p dist
    make dist
    
    popd
}

build_data_webapp_zip() {
    log "Building the webapp ZIP...", "info"
    pushd ./data/data-simulator

    zip -q data-simulator.zip .env app.js package.json web.config
    zip -q -r data-simulator.zip sensors/ helpers/ collections/ 

    popd
}

build_dependencies() {
    # Build the dependencies
    build_ddotransform_wheel
    build_data_webapp_zip
}

remove_dependencies() {
    # Remove the dependencies
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        log "Removing the dependencies...", "info"
        rm -rf ./src/ddo_transform/dist
        rm -rf ./data/data-simulator/data-simulator.zip
    fi
}

# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd ..
    . ./scripts/common.sh
    log "Building dependencies..." "info"
    build_dependencies
    popd
else
    . ./scripts/common.sh
fi