#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------
FROM --platform=linux/amd64 python:3

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get -y install --no-install-recommends apt-utils 2>&1

# Install git, process tools, lsb-release (common in install instructions for CLIs)
RUN apt-get -y install git procps lsb-release 

# Install any missing dependencies for enhanced language service
RUN apt-get install -y libicu[0-9][0-9]

# Install Azure CLI and application insights and azure devops extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az config set extension.use_dynamic_install=yes_without_prompt
RUN az config set extension.dynamic_install_allow_preview=true
RUN az extension add --name application-insights
RUN az extension add --name azure-devops
RUN az bicep upgrade

# Install jq & makepasswd for some frequently used utility
RUN apt-get update \
    && apt-get -y install jq makepasswd

# Install java
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb \
    $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
    | tee /etc/apt/sources.list.d/adoptium.list
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    temurin-21-jdk
ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64

RUN mkdir /workspace
WORKDIR /workspace

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Set PACKAGE_VERSION to localdev
ENV PACKAGE_VERSION=localdev

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash
