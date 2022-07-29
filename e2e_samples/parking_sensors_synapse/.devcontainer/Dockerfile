#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------
# FROM python:3.7-stretch

# # Configure apt
# ENV DEBIAN_FRONTEND=noninteractive
# RUN apt-get update \
#     && apt-get -y install --no-install-recommends apt-utils 2>&1

FROM ubuntu:20.04

LABEL maintainer="SQL Server Engineering Team"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
     && apt-get -y install --no-install-recommends apt-utils 2>&1

# apt-get and system utilities
RUN apt-get update && apt-get install -y \
	curl apt-transport-https debconf-utils python3-pip \
    && rm -rf /var/lib/apt/lists/*

# adding custom MS repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

# install SQL Server drivers and tools
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev 
#msodbcsql18 mssql-tools18
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

RUN apt-get -y install locales
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Install git, process tools, lsb-release (common in install instructions for CLIs)
RUN apt-get -y install git procps lsb-release 

# Install any missing dependencies for enhanced language service, along with password generator
RUN apt-get install -y libicu[0-9][0-9] && apt-get install -y makepasswd

# Install Azure CLI and application insights and azure devops extension
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az extension add --name application-insights
RUN az extension add --name azure-devops

# Install Databricks CLI
RUN pip3 install databricks-cli

# Install jq & makepasswd for some frequently used utility
RUN apt-get update \
    && apt-get -y install jq makepasswd

# Install java
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64

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