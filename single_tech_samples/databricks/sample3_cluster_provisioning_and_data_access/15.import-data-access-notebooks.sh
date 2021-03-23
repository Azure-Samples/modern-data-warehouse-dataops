#!/usr/bin/env bash

set -e

databricks workspace import -l PYTHON -f JUPYTER -o ./access-data-via-mount.ipy /access-data-via-mount
databricks workspace import -l PYTHON -f JUPYTER -o ./access-data-ad-passthrough.ipy /access-data-ad-passthrough