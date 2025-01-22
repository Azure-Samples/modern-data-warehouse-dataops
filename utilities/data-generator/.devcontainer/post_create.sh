#!/usr/bin/env bash
export PATH=$PATH:~/.local/bin

# ensure configuration for extensions is current
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true

# zshrc configuration
echo 'export PATH=$PATH:~/.local/bin' >>~/.zshrc
echo "PROMPT='%F{green}%n@%F{blue}%m:%F{yellow}%~%F{reset}%# '" >>~/.zshrc
chmod +x ~/.zshrc
source ~/.zshrc

# Navigate to the workspace directory, (MDW's repo root where .git folder is present).
cd /workspace

# Install the package in editable mode with development dependencies
pip install -e ".[dev]"

# Configure Git to mark /workspace as a safe directory
git config --global --add safe.directory /workspace

# Install pre-commit hooks
pre-commit install

# Find and remove all directories named "*.egg-info"
find . -type d -name "*.egg-info" -exec rm -rf {} +
