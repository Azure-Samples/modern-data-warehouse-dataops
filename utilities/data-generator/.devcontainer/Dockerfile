#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------
FROM mcr.microsoft.com/devcontainers/javascript-node

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive

RUN sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
RUN sudo apt update
RUN sudo apt-get install terraform


# Install git, process tools, lsb-release (common in install instructions for CLIs)
RUN apt-get -y install git procps lsb-release zip

# Install any missing dependencies for enhanced language service
RUN apt-get install -y libicu[0-9][0-9]

# Install Azure CLI and application insights and azure devops extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az config set extension.use_dynamic_install=yes_without_prompt
RUN az config set extension.dynamic_install_allow_preview=true
RUN az bicep upgrade

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
