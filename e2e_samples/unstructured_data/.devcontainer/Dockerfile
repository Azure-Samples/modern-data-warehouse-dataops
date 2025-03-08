FROM --platform=linux/amd64 ubuntu:22.04

# Create vscode user
ARG USERNAME=vscode
RUN useradd -m $USERNAME

# Set the working directory
RUN mkdir /workspace
WORKDIR /workspace

# Install Python, pip, git, curl, wget, gnupg, lsb-release, and other required packages
RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl zsh lsb-release unzip gnupg wget software-properties-common shfmt jq gh

# Upgrade pip, setuptools, and wheel
RUN pip install --upgrade pip setuptools wheel
RUN pip install black pre-commit mypy

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Download the package to configure the Microsoft repo
RUN curl -sSL -O https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)/packages-microsoft-prod.deb
# Install the package
RUN dpkg -i packages-microsoft-prod.deb
# Delete the file
RUN rm packages-microsoft-prod.deb

RUN curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# Update the package list and install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release

# Add NodeSource APT repository for Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -

# Install Node.js and npm
RUN apt-get install -y nodejs

RUN az extension add --name application-insights

# Install the SQL driver
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql18
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools18
RUN echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.zshrc
RUN echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc

# Set the user to USERNAME
USER $USERNAME

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash
