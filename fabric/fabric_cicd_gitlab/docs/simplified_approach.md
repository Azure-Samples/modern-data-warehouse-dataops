# Simplified Update Item Script – Usage Instructions

## Overview

The [`simplified_update_item_from_ws.sh`](../src/simplified_update_item_from_ws.sh) script takes care of downloading items from Fabric so that developers can then commit those into source control. The script is designed to:

- Authenticate with the Fabric API (refreshing the API token if expired).
- Retrieve the specified workspace by name (provided as an input parameter).
- Locate an item within that workspace that matches the provided item name and type.
- Download the item's definition (or metadata if the item type does not support definition retrieval).
- Save the definition files locally for further processing (e.g., version control, CI/CD).

The [`simplified_update_item_from_git.sh`](../src/simplified_update_item_from_git.sh) script takes care of pushing to Fabric the local changes to item metadata or definitions. The script is designed to:

- Authenticate with the Fabric API (refreshing the API token if expired).
- Retrieve the workspace ID based on the provided workspace name.
- Locate an item within that workspace by looking at the item name and type specified in the item definition files stored in the provided local folder.
- If there is no matching item in the workspace, the script creates a new item. Otherwise the matching item is updated. Creation or update is achieved by sending via APIs the definition of the Fabric item (e.g., DataPipeline, Environment, Notebook, etc.) from the local filesystem to the specified Microsoft Fabric workspace.

## Prerequisite Software

- **Bash**: The script is written in Bash and requires a Unix-like shell.
- **Azure CLI (az)**: Used to generate a Fabric API token. Also used by the helper functions to make REST API calls to Fabric.
- **jq**: For processing JSON responses.
- **curl**: For HTTP requests made in the long-running operations.
- **Git**: To manage your repository.
- A proper configuration file located at `./config/.env` containing the following variables:
  - `TENANT_ID`: Required. Your Entra Tenant ID, used to authenticate and retrieve an access token
  - `FABRIC_API_BASEURL`: Required. The base URL for the Fabric API. No need to update this as it's fixed.
  - `FABRIC_USER_TOKEN`: Optional. The authentication token for the Fabric API. This will be filled by the script, can be left as is.

## Assumptions

The sample assumes the following:

- the script should be executed using a user that has access to the Fabric workspace for which items need to be downloaded, with minimal permissions of `Contributor`.
- The Fabric workspace from which items should be downloaded is assigned to a **running** Fabric capacity. If the capacity is paused the script will fail.

## How to Use the Scripts

### Before running the scripts

1. **Ensure Environment Setup:**
   - Verify that all the prerequisite software is installed and available in your system’s PATH.
   - Create a copy of the [`.envtemplate`](../config/.envtemplate) file and rename it to `.env`

   ```bash
   cp ./config/.envtemplate ./config/.env
   ```

   - Edit the newly created `.env` file, filling the required parameters (`TENANT_ID`)
   - Load environment variables

   ```bash
   source config/.env
   ```

   - Login to Azure CLI with your user or SPN/MI, below instructions for user login with device code:

   ```bash
   az login --use-device-code -t $TENANT_ID
   ```

### Running the script: `simplified_update_item_from_ws.sh`

1. **Script Parameters:**
   The script requires four parameters:
   - **workspace_name**: The display name of the Fabric workspace.
   - **item_name**: The name of the Fabric item to retrieve.
   - **item_type**: The type of the Fabric item (e.g., Notebook, DataPipeline) used to disambiguate items with the same name.
   - **folder**: The local destination folder in your filesystem (local repository) where the retrieved item definition (or metadata) will be stored.

1. **Example Usage:**

   ```bash
   ./src/simplified_update_item_from_ws.sh "MyWorkspaceName" "MyNotebookName" "Notebook" "./fabric"
   ```

   This command will:
   - Check if the Fabric API token is expired; if so, it will refresh the token and reload environment variables.
   - Retrieve the workspace ID corresponding to `MyWorkspaceName`.
   - Look for the item `MyNotebookName` of type `Notebook` within that workspace. Review the list of supported [Fabric item types](https://learn.microsoft.com/rest/api/fabric/core/items/list-items?tabs=HTTP#itemtype).
   - Download the item definition and store the resulting files in the `./fabric` folder.

1. **Commit to source control**
   - **Manual Step**: After the item definition is downloaded locally, the files can be committed to the feature branch with the preferred mechanism: for example using VS Code or by executing a `git commit` command.

### Running the script: `simplified_update_item_from_git.sh`

1. **Script Parameters:**
   The script requires two parameters:
   - **workspace_name**: The display name of the Fabric workspace.
   - **item_folder**: The source folder where the item definition files are located.

1. **Example Usage:**

   ```bash
   ./src/simplified_update_item_from_git.sh "MyWorkspaceName" "./fabric/MyNotebookName.Notebook"
   ```

   This command will:
   - Check if the Fabric API token is expired; if so, it will refresh the token and reload environment variables.
   - Retrieve the workspace ID corresponding to `MyWorkspaceName`.
   - Verify that the folder `./fabric/MyNotebookName.Notebook` contains required item metadata and/or definition files.
   - Create or Update the corresponding Fabric item in the `MyWorkspaceName` workspace, by using metadata and definition files found in the `./fabric/MyNotebookName.Notebook` folder.

## Troubleshooting

- If the script cannot find the workspace or item, double-check the names and types.
- Ensure that the right Tenant ID is provided. The script will attempt to refresh expired tokens automatically.
- Verify that the necessary tools (az, jq, curl, git) are installed and accessible.

## Remarks

The simplified approach has only been tested with items of type: DataPipeline, Lakehouse, Notebook, Environment. Other item types have not been tested and the sample might not be mimicking the current Fabric git integration approach. If a specific item type is important for you/your company, contributions to this repository would be more than welcome!

### Known Gaps

When a Lakehouse or Environment item is synced only a `.platform` file is produced. This deviates from the current Git integration behavior:

- for Lakehouse items, Fabric git integration generates also a `shortcuts.metadata.json` file, containing the list of shortcuts that point to other Lakehouse items (either in the same or other workspaces of the same tenant).
- for Environment items, Fabric git integration generates also a `Settings` folder that contains the Spark pool `yml` settings definition file.

These omissions are an intentional simplification in this approach to streamline the process and focus on core functionality. Users requiring full parity with Fabric Git integration behavior may need to extend the scripts accordingly.
