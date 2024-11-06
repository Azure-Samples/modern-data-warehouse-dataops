ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# Install Additional Packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get upgrade \
    && apt-get -y install --no-install-recommends \
    git \
    jq \
    make \
    nodejs \
    npm \
    python3 \
    python3-pip \
    xz-utils

# Install shfmt
RUN curl -SsL "https://github.com/mvdan/sh/releases/download/v3.2.4/shfmt_v3.2.4_linux_amd64" -o "shfmt" \
    && mv shfmt /usr/local/bin \
    && chown vscode /usr/local/bin/shfmt \
    && chmod a+x /usr/local/bin/shfmt

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Databricks CLI
RUN pip3 install setuptools \
    && pip3 install wheel \
    && pip3 install databricks-cli

# Install markdown-link-check
RUN npm install -g markdown-link-check
