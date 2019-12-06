
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
set -o xtrace # For debugging

# Set path
dir_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$dir_path"


###################
# Requires the following to be set:
#
# RELEASE_ID=
# MOUNT_DATA_PATH=
# WHEEL_FILE_PATH=

# Set DBFS libs path
dbfs_libs_path=dbfs:${MOUNT_DATA_PATH}/libs/release_${RELEASE_ID}

# Upload dependencies
echo "Uploading libraries dependencies to DBFS..."
databricks fs cp ./libs/ "${dbfs_libs_path}" --recursive

echo "Uploading app libraries to DBFS..."
databricks fs cp $WHEEL_FILE_PATH "${dbfs_libs_path}"

# Upload notebooks to workspace
echo "Uploading notebooks to workspace..."
databricks workspace import_dir "notebooks" "/releases/release_${RELEASE_ID}/"
