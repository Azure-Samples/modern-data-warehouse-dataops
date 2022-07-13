#-----------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
#-----------------------------------------------------------------------------------------

FROM python:3.9.13

# Copy default endpoint specific user settings overrides into container to specify Python path
COPY .devcontainer/settings.vscode.json /root/.vscode-remote/data/Machine/settings.json

# Install pylint
RUN pip install --upgrade pip && \
    pip install pylint

# Install git, process tools
RUN apt-get update && apt-get -y install git procps

# Install OpenJDK-11
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get install -y ant && \
    apt-get clean;


ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

# Install any missing dependencies for enhanced language service
RUN apt-get install -y libicu[0-9][0-9]

RUN mkdir /workspace
WORKDIR /workspace

# Add starship
RUN apt install -y curl
RUN curl -o install.sh -fsSL https://starship.rs/install.sh
RUN chmod +x install.sh
RUN ./install.sh -y
RUN printf 'eval "$(starship init bash)"' >> '/root/.bashrc'
RUN rm install.sh

# Add editor setting
RUN apt install -y nano
RUN printf 'EDITOR=nano' >> '/root/.bashrc'


# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Add path for pytest
ENV PYTHONPATH /workspaces/config_driven_data_pipelines/src:/workspaces/config_driven_data_pipelines/tests

# Add env variable for pyspark
ENV PYSPARK_PYTHON python3.9
