# Use Ubuntu Image
FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Update and install required system dependencies
RUN apt update \
  && apt install -y sudo vim software-properties-common curl unzip\
  && apt clean

# Copy and install dev dependencies
COPY requirements-dev.txt /tmp/requirements-dev.txt
RUN pip install -r /tmp/requirements-dev.txt && \
  rm /tmp/requirements-dev.txt

# Set the working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
