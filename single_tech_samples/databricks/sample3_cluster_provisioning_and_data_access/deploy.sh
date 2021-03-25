#!/usr/bin/env bash

set -e

/bin/bash ./scripts/upload-sample-data.sh
/bin/bash ./scripts/deploy-default-and-hc-clusters.sh
/bin/bash ./scripts/configure-databricks-cli.sh
/bin/bash ./scripts/import-data-access-notebooks.sh