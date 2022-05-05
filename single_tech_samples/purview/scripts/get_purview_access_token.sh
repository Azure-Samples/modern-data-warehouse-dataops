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
# Logs into Purview with SPN and gets access token
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PURVIEW_SPN_APP_KEY
# PURVIEW_SPN_APP_ID
# PURVIEW_ACCOUNT_NAME

###############
# Login to Purview

az_sub=$(az account show --output json)
az_tenant_id=$(echo $az_sub | jq -r '.tenantId')

loginURL="https://login.microsoftonline.com/$az_tenant_id/oauth2/token"
loginBody="grant_type=client_credentials&client_id=$PURVIEW_SPN_APP_ID&client_secret=$PURVIEW_SPN_APP_KEY&resource=https%3A%2F%2Fpurview.azure.net"
access_token=$(curl -X POST -d $loginBody $loginURL | jq -r '.access_token')

echo $access_token
