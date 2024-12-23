#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

echo "[Info] ############ STARTING PRE REQUISITE CHECK ############"
ENV_FILE=${1:-"../.env"}

# Function to check if Python 3 is installed and meets the version requirement
check_python_version() {
  if ! command -v python3 &>/dev/null; then
    echo "[Error] Python is not installed or not available in PATH."
    exit 1
  fi

  PYTHON_INTERPRETER=$(which python3)
  echo "[Info] Using Python interpreter: $PYTHON_INTERPRETER"

  PYTHON_VERSION=$(python3 --version 2>&1)
  echo "[Info] $PYTHON_VERSION found."

  PYTHON_VERSION_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
  PYTHON_VERSION_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")

  if [[ "$PYTHON_VERSION_MAJOR" -lt 3 || ("$PYTHON_VERSION_MAJOR" -eq 3 && "$PYTHON_VERSION_MINOR" -lt 9) ]]; then
    echo "[Error] Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} found. Python 3.9 or higher is required."
    exit 1
  fi
  echo "[Info] Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} is installed and meets the requirement (>= 3.9)."
}

# Function to check if required Python libraries are installed
check_python_libraries() {
  local libraries=("requests")
  for library in "${libraries[@]}"; do
    if ! python3 -m pip show "$library" &>/dev/null; then
      echo "[Error] '$library' library is not installed."
      exit 1
    fi
    echo "[Info] '$library' library is installed."
  done
}

# Function to check if Terraform is installed and meets version requirements
check_terraform() {
  if ! command -v terraform &>/dev/null; then
    echo "[Error] Terraform is not installed or not available in PATH."
    exit 1
  fi

  TERRAFORM_VERSION=$(terraform version | grep -oP '^Terraform\s+v\K[0-9]+\.[0-9]+\.[0-9]+')

  if [[ $? -ne 0 || -z "$TERRAFORM_VERSION" ]]; then
    echo "[Error] Failed to retrieve Terraform version."
    exit 1
  fi

  echo "[Info] Terraform version $TERRAFORM_VERSION is installed."
}

# Function to check if Azure CLI is installed and meets version requirements
check_azure_cli() {
  if ! command -v az &>/dev/null; then
    echo "[Error] Azure CLI is not installed or not available in PATH."
    exit 1
  fi
  AZURE_CLI_VERSION=$(az --version | head -n1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9]+')
  echo "[Info] Azure CLI version $AZURE_CLI_VERSION is installed."
}

# Function to check if jq (command-line JSON processor) is installed
check_jq() {
  if ! command -v jq &>/dev/null; then
    echo "[Error] 'jq' is not installed or not available in PATH. You can install 'jq' using: sudo apt-get install jq (for Ubuntu)."
    exit 1
  fi
  echo "[Info] 'jq' is installed."
}

# Function to check if required environment variables are set and non-empty
check_env_vars() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "[Error] .env file not found at $ENV_FILE"
    exit 1
  fi

  REQUIRED_ENV_VARS=$(grep -oP '^\s*export\s+\K[A-Z_][A-Z0-9_]*' "$ENV_FILE")
  COMPULSORY_VARS=("TENANT_ID" "SUBSCRIPTION_ID" "RESOURCE_GROUP_NAME" "BASE_NAME" "FABRIC_WORKSPACE_ADMIN_SG_NAME" "FABRIC_CAPACITY_ADMINS")
  local missing_compulsory_vars=()

  for var in "${COMPULSORY_VARS[@]}"; do
    if [ -z "${!var-}" ]; then
      missing_compulsory_vars+=("$var")
    fi
  done

  if [ ${#missing_compulsory_vars[@]} -gt 0 ]; then
    echo "[Error] The following compulsory environment variables are missing or empty:"
    for var in "${missing_compulsory_vars[@]}"; do
      echo "  - $var"
    done
    echo "Please set the above variables or source the .env file."
    exit 1
  fi

  echo "[Info] All compulsory environment variables are set and non-empty."
}

# Main flow
check_python_version
check_python_libraries
check_terraform
check_azure_cli
check_jq
check_env_vars

echo "[Info] ############ PRE REQUISITE CHECK FINISHED ############"
