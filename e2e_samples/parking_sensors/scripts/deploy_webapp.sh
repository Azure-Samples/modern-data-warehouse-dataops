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
set -o errexit
set -o pipefail
set -o nounset

pushd ./data/data-simulator

zip -q data-simulator.zip .env app.js package.json web.config
zip -q -r data-simulator.zip sensors/ helpers/ collections/

az webapp config appsettings set --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
az webapp deploy --clean true --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --src-path ./data-simulator.zip --type zip --async true

# Restart the webapp to ensure the latest changes are applied
az webapp stop --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME"
az webapp start --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME"

rm data-simulator.zip

popd