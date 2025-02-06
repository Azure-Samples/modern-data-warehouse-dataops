FROM --platform=linux/amd64 python:3.11

# Install OpenJDK 8 and Python
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
    RUN echo "deb https://packages.adoptium.net/artifactory/deb \
        $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
        | tee /etc/apt/sources.list.d/adoptium.list
RUN \
  apt-get update && \
  apt-get -y install --no-install-recommends \
    temurin-21-jdk && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/ddo_transform

COPY . .

RUN pip install --no-cache-dir -r requirements_dev.txt && \
    make clean && \
    make lint && \
    make test && \
    make docs && \
    make dist

