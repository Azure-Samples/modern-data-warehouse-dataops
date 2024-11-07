#!/bin/bash

# Configure az devops cli
az devops configure --defaults organization="$AZDO_ORGANIZATION_URL" project="$AZDO_PROJECT"

# Install requirements depending if devcontainer was openned at root or in parking_sensor folder.
pip install -r /workspace/e2e_samples/parking_sensors/src/ddo_transform/requirements_dev.txt

#Install New Databricks CLI
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

