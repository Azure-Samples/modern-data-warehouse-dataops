# [Choice] Python version: 3, 3.8, 3.7, 3.6
ARG PYTHON_VARIANT=3.9
FROM python:${PYTHON_VARIANT}

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1

# Install git, process tools, lsb-release (common in install instructions for CLIs)
RUN apt-get -y install git procps lsb-release 

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install jq
RUN apt-get update \
    && apt-get -y install jq

RUN mkdir /workspace
WORKDIR /workspace

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash