#!/usr/bin/env bash

set -e

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}

if [[ -z "$DEPLOYMENT_PREFIX" ]]; then
    echo "No deployment prefix [DEPLOYMENT_PREFIX] specified."
    exit 1
fi

# Import the notebooks

mountTmpFile="./access-data-via-mount.tmp.ipy"
passthroughTmpFile="./access-data-ad-passthrough.tmp.ipy"

sed -e "s/\${DEPLOYMENT_PREFIX}/$DEPLOYMENT_PREFIX/g" < ./access-data-via-mount.ipy > "$mountTmpFile"
sed -e "s/\${DEPLOYMENT_PREFIX}/$DEPLOYMENT_PREFIX/g" < ./access-data-ad-passthrough.ipy > "$passthroughTmpFile"

databricks workspace import -l PYTHON -f SOURCE -o "$mountTmpFile" /access-data-via-mount
databricks workspace import -l PYTHON -f SOURCE -o "$passthroughTmpFile" /access-data-ad-passthrough

cat <<EOF
Notebook "access-data-via-mount" and "access-data-ad-passthrough" have been uploaded to the workspace.
Please go to the Databricks workspace and run the notebooks using the corresponding cluster.
- via mount => use default cluster
- via ad passthrough => use high concurrency cluster
EOF