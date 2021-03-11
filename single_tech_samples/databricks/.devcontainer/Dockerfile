ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# Install Additional Packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get upgrade \
    && apt-get -y install --no-install-recommends \
        git \
        xz-utils \
        python3 \
        python3-pip

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Databricks CLI
RUN pip3 install setuptools \
    && pip3 install wheel \
    && pip3 install databricks-cli
