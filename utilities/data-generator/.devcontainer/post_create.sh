#!/bin/bash

# ensure configuration for extensions is current
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true

