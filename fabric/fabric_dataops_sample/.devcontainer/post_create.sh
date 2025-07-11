#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

export PATH="${PATH}:${HOME}/.local/bin"

# zshrc configuration
echo 'export PATH=$PATH:~/.local/bin' >> ~/.zshrc
echo "PROMPT='%F{green}%n@%F{blue}%m:%F{yellow}%~%F{reset}%# '" >> ~/.zshrc
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
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
