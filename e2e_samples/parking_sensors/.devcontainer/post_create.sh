#!/bin/bash

# ensure configuration for extensions is current
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true


# Install requirements depending if devcontainer was openned at root or in parking_sensor folder.
pip install -r /workspace/e2e_samples/parking_sensors/src/ddo_transform/requirements_dev.txt

# Install the Databricks CLI
# This script was reused from the Databricks CLI installation script located here
# https://github.com/databricks/setup-cli/blob/main/install.sh
# Check for the latest release version here: https://github.com/databricks/cli/releases
VERSION="0.233.0"
FILE="databricks_cli_$VERSION"

#/home/mdwuser
# Include operating system in file name.
OS="$(uname -s | cut -d '-' -f 1)"
case "$OS" in
Linux)
    FILE="${FILE}_linux"
    TARGET="/usr/local/bin"
    ;;
Darwin)
    FILE="${FILE}_darwin"
    TARGET="/usr/local/bin"
    ;;
MINGW64_NT)
    FILE="${FILE}_windows"
    TARGET="/c/Windows"
    ;;
*)
    echo "Unknown operating system: $OS"
    exit 1
    ;;
esac

# Set target to ~/bin if DATABRICKS_RUNTIME_VERSION environment variable is set.
if [ -n "$DATABRICKS_RUNTIME_VERSION" ]; then
    # Set the installation target to ~/bin when run on DBR
    TARGET="$HOME/bin"

    # Create the target directory if it does not exist
    mkdir -p "$TARGET"
fi

# Include architecture in file name.
ARCH="$(uname -m)"
case "$ARCH" in
i386)
    FILE="${FILE}_386"
    ;;
x86_64)
    FILE="${FILE}_amd64"
    ;;
arm)
    FILE="${FILE}_arm"
    ;;
arm64|aarch64)
    FILE="${FILE}_arm64"
    ;;
*)
    echo "Unknown architecture: $ARCH"
    exit 1
    ;;
esac

# Make sure the target directory is writable.
if [ ! -w "$TARGET" ]; then
    echo "Target directory $TARGET is not writable."
    echo "Please run this script through 'sudo' to allow writing to $TARGET."
    exit 1
fi

# Make sure we don't overwrite an existing installation.
if [ -f "$TARGET/databricks" ]; then
    echo "Target path $TARGET/databricks already exists."
    echo "If you have an existing Databricks CLI installation, please first remove it using"
    echo "  sudo rm '$TARGET/databricks'"
    exit 1
fi

# Change into temporary directory.
tmpdir="$(mktemp -d)"
cd "$tmpdir"
echo "tempdir: $tmpdir"

# Download release archive.
wget -q https://github.com/databricks/cli/releases/download/v$VERSION/$FILE.zip -O /$tmpdir/${FILE}.zip

# Verify the checksum
cd /$tmpdir && sha256sum ${FILE}.zip > /$tmpdir/${FILE}.zip.sha256
cd /$tmpdir 
# Run the sha256sum check
sha256sum -c ${FILE}.zip.sha256

# Check the exit status of the sha256sum command
if [ $? -ne 0 ]; then
  echo "Checksum validation failed. Exiting."
  exit 1
else
  echo "Checksum validation succeeded."
fi

# Unzip the downloaded file
unzip -q /$tmpdir/${FILE}.zip #-d /home/mdwuser/databricks

# Add databricks to path.
chmod +x ./databricks
cp ./databricks "$TARGET"

echo "Installed $("databricks" -v) at $TARGET/databricks."

# Clean up the zip file and checksum
rm /$tmpdir/${FILE}.zip /$tmpdir/${FILE}.zip.sha256

# Clean up temporary directory.
cd "$OLDPWD"
rm -rf "$tmpdir" || true
echo "Cleaned up $tmpdir."

