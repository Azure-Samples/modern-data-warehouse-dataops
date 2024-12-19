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


#######################################################
# Deploys ADF artifacts
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset

###################
# REQUIRED ENV VARIABLES:
#
# AZURE_SUBSCRIPTION_ID
# RESOURCE_GROUP_NAME
# DATAFACTORY_NAME
# ADF_DIR

. ./scripts/common.sh

# Consts
apiVersion="2018-06-01"
baseUrl="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}"
adfFactoryBaseUrl="$baseUrl/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.DataFactory/factories/${DATAFACTORY_NAME}"

log "Deploying Data Factory artifacts."

# Deploy all Linked Services
create_adf_linked_service "Ls_KeyVault_01"
create_adf_linked_service "Ls_AdlsGen2_01"
create_adf_linked_service "Ls_AzureSQLDW_01"
create_adf_linked_service "Ls_AzureDatabricks_01"
create_adf_linked_service "Ls_Http_Parking_Bay_01"
# Deploy all Datasets
create_adf_dataset "Ds_AdlsGen2_MelbParkingData"
create_adf_dataset "Ds_Http_Parking_Bay"
create_adf_dataset "Ds_Http_Parking_Bay_Sensors"
# Deploy all Pipelines
create_adf_pipeline "P_Ingest_MelbParkingData"
# Deploy triggers
create_adf_trigger "T_Sched"

log "Completed deploying Data Factory artifacts."
