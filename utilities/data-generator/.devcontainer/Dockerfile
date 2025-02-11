FROM --platform=linux/amd64 ubuntu:22.04

# Create vscode user
ARG USERNAME=vscode
RUN useradd -m $USERNAME

# Set the working directory
RUN mkdir /workspace
WORKDIR /workspace

# Ensure system dependencies are up-to-date
RUN apt-get update && apt-get install -y curl ca-certificates

# Add NodeSource repository and install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Verify Node.js version after installation
RUN node -v && npm -v

# Install Python, pip, git, curl, wget, and other required packages
RUN apt-get install -y python3 python3-pip git zsh lsb-release unzip gnupg wget software-properties-common shfmt jq gh

# Upgrade pip, setuptools, and wheel
RUN pip install --upgrade pip setuptools wheel

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform

# Install TFLint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update && apt-get install -y trivy

# Set the user to USERNAME
USER $USERNAME
