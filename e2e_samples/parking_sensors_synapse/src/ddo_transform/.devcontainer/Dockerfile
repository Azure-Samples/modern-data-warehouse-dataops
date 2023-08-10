#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------
FROM python:3.7

ARG USERNAME=mdwuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1

# Install git, process tools, lsb-release (common in install instructions for CLIs)
RUN apt-get -y install git procps lsb-release 

# Install any missing dependencies for enhanced language service
RUN apt-get install -y libicu[0-9][0-9]

# Install java
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb \
$(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
| tee /etc/apt/sources.list.d/adoptium.list
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
      temurin-11-jdk


RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME
    
RUN mkdir /home/$USERNAME/workspace
WORKDIR /home/$USERNAME/workspace

# Install Python dependencies from requirements.txt and requirements_dev.txt
COPY requirements.txt* requirements_dev.txt* /home/$USERNAME/workspace/
RUN pip install -r requirements_dev.txt \
    && rm requirements_dev.txt* \
    && pip install -r requirements.txt \ 
    && rm requirements.txt*

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Set PACKAGE_VERSION to localdev
ENV PACKAGE_VERSION=localdev

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash

# Set user to non-root user to get rid of permission errors
USER $USERNAME