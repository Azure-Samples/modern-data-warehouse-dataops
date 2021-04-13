ARG VARIANT="3"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT}

RUN apt-get install -y sudo git curl make \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN az config set extension.use_dynamic_install=yes_without_prompt

COPY ./requirements.txt /workspaces/
RUN pip install -r /workspaces/requirements.txt
