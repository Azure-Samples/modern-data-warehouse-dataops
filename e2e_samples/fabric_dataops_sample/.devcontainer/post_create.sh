#!/usr/bin/env bash
export PATH=$PATH:~/.local/bin
echo 'export PATH=$PATH:~/.local/bin' >>~/.zshrc
echo "PROMPT='%F{green}%n@%F{blue}%m:%F{yellow}%~%F{reset}%# '" >>~/.zshrc
chmod +x ~/.zshrc
source ~/.zshrc
cd /workspace
pip install -e ".[dev]"
pre-commit install
find . -type d -name "*.egg-info" -exec rm -rf {} +
