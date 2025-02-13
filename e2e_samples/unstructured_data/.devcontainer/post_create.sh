#!/usr/bin/env bash
export PATH=$PATH:~/.local/bin

# zshrc configuration
echo 'export PATH=$PATH:~/.local/bin' >>~/.zshrc
echo "PROMPT='%F{green}%n@%F{blue}%m:%F{yellow}%~%F{reset}%# '" >>~/.zshrc
chmod +x ~/.zshrc
source ~/.zshrc

# Navigate to the workspace directory, (MDW's repo root where .git folder is present).
cd /workspace

# Install the packages
pip install -r ./e2e_samples/unstructured_data/src/requirements.txt

# Configure Git to mark /workspace as a safe directory
git config --global --add safe.directory /workspace

# Install pre-commit hooks
pre-commit install

# Find and remove all directories named "*.egg-info"
find . -type d -name "*.egg-info" -exec rm -rf {} +
