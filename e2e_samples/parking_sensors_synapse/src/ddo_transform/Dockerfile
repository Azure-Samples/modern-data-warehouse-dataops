FROM python:3.7.3

# Install OpenJDK 8 and Python
RUN \
  apt-get update && \
  apt-get install -y openjdk-8-jdk && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/ddo_transform

COPY . .

RUN pip install --no-cache-dir -r requirements_dev.txt && \
    make clean && \
    make lint && \
    make test && \
    make docs && \
    make dist

