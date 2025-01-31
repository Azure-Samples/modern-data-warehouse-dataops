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

pushd ./data/data-simulator

zip -q data-simulator.zip app.js 
zip -q data-simulator.zip .env
zip -q data-simulator.zip package.json
zip -q data-simulator.zip web.config
zip -q -r data-simulator.zip sensors/
zip -q -r data-simulator.zip helpers/
zip -q -r data-simulator.zip collections/

az webapp config appsettings set --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
az webapp deploy --clean --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_NAME" --src-path ./data-simulator.zip --type zip --async true

rm data-simulator.zip

popd