#!/usr/bin/env bash

set -e

DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-}

if [[ -z "$DEPLOYMENT_PREFIX" ]]; then
    echo "No deployment prefix [DEPLOYMENT_PREFIX] specified."
    exit 1
fi

# Import the notebooks

mountTmpFile="./access-data-mount-via-account-key.tmp.ipy"
passthroughTmpFile="./access-data-mount-via-ad-passthrough.tmp.ipy"

sed -e "s/\${DEPLOYMENT_PREFIX}/$DEPLOYMENT_PREFIX/g" < ./access-data-mount-via-account-key.ipy > "$mountTmpFile"
sed -e "s/\${DEPLOYMENT_PREFIX}/$DEPLOYMENT_PREFIX/g" < ./access-data-mount-via-ad-passthrough.ipy > "$passthroughTmpFile"

databricks workspace import -l PYTHON -f SOURCE -o "$mountTmpFile" /access-data-mount-via-account-key
databricks workspace import -l PYTHON -f SOURCE -o "$passthroughTmpFile" /access-data-mount-via-ad-passthrough

cat <<EOF
Notebook "access-data-mount-via-account-key" and "access-data-mount-via-ad-passthrough"
have been uploaded to the workspace.

Please go to the Databricks workspace and run the notebooks using the corresponding cluster.
- access-data-mount-via-account-key => use default cluster
- access-data-mount-via-ad-passthrough => use high concurrency cluster
EOF