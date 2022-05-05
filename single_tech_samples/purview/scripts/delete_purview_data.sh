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
# Deletes data from Purview that matches the search criteria
# To delete all data, leave the keyword blank
#
# Prerequisites:
# - User is logged in to the azure cli
# - Correct Azure subscription is selected
#######################################################

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

tenantId=""         # enter the tenant id
purview=""          # enter the purview instance name, eg. my-dev-babylon
PurviewSPNAppId=""  # enter the Service Principal App ID with rights to Purview
PurviewSPNKey=""    # enter the Service Principal Key with rights to Purview
keyword=""          # enter the keyword to search for

loginURL="https://login.microsoftonline.com/$tenantId/oauth2/token"
searchURL="https://$purview.catalog.purview.azure.com/api/atlas/v2/search/advanced"
deleteURL="https://$purview.catalog.purview.azure.com/api/atlas/v2/entity/guid/"


loginBody="grant_type=client_credentials&client_id=$PurviewSPNAppId&client_secret=$PurviewSPNKey&resource=https%3A%2F%2Fpurview.azure.net"
access_token=$(curl -X POST -d $loginBody $loginURL | jq -r '.access_token')

headers="Authorization: Bearer $access_token"

searchBody='{"keywords":"'$keyword'"}'

AnythingLeftToDelete=1

while [ $AnythingLeftToDelete -ne 0 ]; do
    searchResult=$(curl -X POST -H "$headers" --header 'Content-Type: application/json' --data "$searchBody" --url $searchURL)
    AnythingLeftToDelete=$(echo $searchResult | jq -r '.["@search.count"]')
    for row in $(echo "${searchResult}" | jq -r '.value[] | @base64'); do
        _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
        }

        guid=$(_jq .id)
        curl -X DELETE -H "$headers" --header --url $deleteURL$guid
        echo "Deleted "$guid 
    done

done

