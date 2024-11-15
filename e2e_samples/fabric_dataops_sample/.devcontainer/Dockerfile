FROM ubuntu:22.04

# Create vscode user
ARG USERNAME=vscode
RUN useradd -m $USERNAME

# Set the working directory
RUN mkdir /workspace
WORKDIR /workspace

# Install Python, pip, git, zsh and other required packages
RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl zsh lsb-release unzip gnupg software-properties-common

# Upgrade pip, setuptools, and wheel
RUN pip install --upgrade pip setuptools wheel

# Install Azure CLI and application insights and azure devops extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az extension add --name application-insights
RUN az extension add --name azure-devops

# Add the HashiCorp GPG key and repository
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
RUN apt-get update && apt-get install -y terraform

# Install TFLint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install TFSec
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Install Trivy
RUN curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.38.0/trivy_0.38.0_Linux-64bit.tar.gz | tar -xzv -C /usr/local/bin trivy

# Set the user to USERNAME
USER $USERNAME
