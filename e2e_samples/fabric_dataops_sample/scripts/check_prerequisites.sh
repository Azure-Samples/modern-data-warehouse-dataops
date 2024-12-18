#!/bin/bash

echo "[Info] ############ STARTING PRE REQUISITE CHECK ############"
# Path to the .env file (default is "../.env")
ENV_FILE=${1:-"../.env"}

# -------------------------------
# Function to check if Python is installed and its version
check_python_version() {
    if ! command -v python3 &>/dev/null; then
        echo "[Error] Python is not installed or not available in PATH."
        exit 1
    fi

    # Get the Python interpreter being used
    PYTHON_INTERPRETER=$(which python3)
    echo "[Info] Using Python interpreter: $PYTHON_INTERPRETER"

    # Check if a virtual environment is active
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "[Info] Virtual environment is active: $VIRTUAL_ENV"
    else
        echo "[Info] No virtual environment is active."
    fi

    # Get the Python version
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "[Info] $PYTHON_VERSION found."

    # Get the Python version components
    PYTHON_VERSION_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    PYTHON_VERSION_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")

    # Check if Python version is at least 3.9
    if [[ "$PYTHON_VERSION_MAJOR" -lt 3 || ( "$PYTHON_VERSION_MAJOR" -eq 3 && "$PYTHON_VERSION_MINOR" -lt 9 ) ]]; then
        echo "[Error] Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} found. Python 3.9 or higher is required."
        exit 1
    fi
    echo "[Info] Python version ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR} is installed and meets the requirement (>= 3.9)."
}

# -------------------------------
# Function to check if Python libraries are installed
check_python_libraries() {
    local libraries=("requests" "pandas" "numpy")
    for library in "${libraries[@]}"; do
        if ! python3 -m pip show "$library" &>/dev/null; then
            echo "[Error] '$library' library is not installed."
            exit 1
        fi
        echo "[Info] '$library' library is installed."
    done
}

# -------------------------------
# Function to check if Terraform is installed
check_terraform() {
    if ! command -v terraform &>/dev/null; then
        echo "[Error] Terraform is not installed or not available in PATH."
        exit 1
    fi
    TERRAFORM_VERSION=$(terraform version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
    echo "[Info] Terraform version $TERRAFORM_VERSION is installed."
}

# -------------------------------
# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &>/dev/null; then
        echo "[Error] Azure CLI is not installed or not available in PATH."
        exit 1
    fi
    AZURE_CLI_VERSION=$(az --version | head -n1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9]+')
    echo "[Info] Azure CLI version $AZURE_CLI_VERSION is installed."
}

# -------------------------------
# Function to check if 'jq' is installed
check_jq() {
    if ! command -v jq &>/dev/null; then
        echo "[Error] 'jq' is not installed or not available in PATH. You can install 'jq' using: sudo apt-get install jq (for Ubuntu)."
        exit 1
    fi
    echo "[Info] 'jq' is installed."
}

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "[Error] .env file not found at $ENV_FILE"
    exit 1
fi

# Extract variable names from the .env file (ignore comments and blank lines)
REQUIRED_ENV_VARS=$(grep -oP '^\s*export\s+\K[A-Z_][A-Z0-9_]*' "$ENV_FILE")

if [[ -z "$REQUIRED_ENV_VARS" ]]; then
    echo "[Error] No valid environment variable exports found in $ENV_FILE."
    exit 1
fi

# Function to check if a variable is defined
check_env_vars() {
    local missing_vars=()
    for var in $REQUIRED_ENV_VARS; do
        if ! printenv "$var" &>/dev/null; then
            missing_vars+=("$var")
        fi
    done

    # If there are missing variables, print them and exit
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "[Error] The following required environment variables are not defined:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo "[Info] Source your .env file with: source $ENV_FILE"
        exit 1
    fi
}

# -------------------------------
# Run checks
echo "[Info] Checking system requirements..."
check_python_version
check_python_libraries
check_terraform
check_azure_cli
check_jq


echo "[Info] Checking environment variables..."
check_env_vars

# All checks passed
echo "[Info] All system requirements and environment variables are satisfied."
echo "[Info] ############ PRE REQUISITE CHECK FINISHED ############"
