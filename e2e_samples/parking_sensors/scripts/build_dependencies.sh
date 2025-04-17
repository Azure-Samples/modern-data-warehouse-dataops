#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

build_ddotransform_wheel() {
    # Build the WHL package
    log "Building the WHL package..." "info"
    pushd ./src/ddo_transform > /dev/null

    if [[ -f "dist/ddo_transform-localdev-py2.py3-none-any.whl" ]]; then
        log "It appears the WHL file dist/ddo_transform-localdev-py2.py3-none-any.whl already exists" "info"
    else
        mkdir -p dist
        make dist > /dev/null 2>&1
        log "WHL package build completed", "success"
    fi
    
    popd > /dev/null
}

build_data_webapp_zip() {
    log "Building the webapp ZIP..." "info"
    pushd ./data/data-simulator > /dev/null

    if [[ -f "data-simulator.zip" ]]; then
        log "It appears the ZIP file already exists" "info"
    else
        zip -q data-simulator.zip .env app.js package.json web.config
        zip -q -r data-simulator.zip sensors/ helpers/ collections/ 
    fi
    popd > /dev/null
}

build_dependencies() {
    # Build the dependencies
    build_ddotransform_wheel
    build_data_webapp_zip
}

remove_dependencies() {
    # Remove the dependencies
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        log "Removing the dependencies..." "info"
        rm -rf ./src/ddo_transform/dist
        rm -rf ./data/data-simulator/data-simulator.zip
    fi
}

# if this is run from the scripts directory, get to root folder and run the build_dependencies function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pushd .. > /dev/null
    . ./scripts/common.sh
    log "Building dependencies..." "info"
    build_dependencies
    popd > /dev/null
else
    . ./scripts/common.sh
fi