#!/usr/bin/env bash

# Configure az devops cli
az devops configure --defaults organization="$AZDO_ORGANIZATION_URL" project="$AZDO_PROJECT"

# Install requirements depending if devcontainer was openned at root or in parking_sensor folder.
if [ -f "../e2e_samples/parking_sensors_synapse/src/ddo_transform/requirements_dev.txt" ]; then
    pip install -r ../e2e_samples/parking_sensors_synapse/src/ddo_transform/requirements_dev.txt
elif [ -f "e2e_samples/parking_sensors_synapse/src/ddo_transform/requirements_dev.txt" ]; then
    pip install -r e2e_samples/parking_sensors_synapse/src/ddo_transform/requirements_dev.txt
fi
