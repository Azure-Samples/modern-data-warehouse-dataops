# Github Action to Set Purview Permissions

A github action to manage permissions with purview.

## Problem Statement

Managing purview permissions cannot be easily done programmatically because permissions are managed in the data plane and not in IAM. This makes it difficult to assign permissions using IaCs such as terraform or bicep. Also, the only permission currently available to assign via `az cli` is the root collection admin.

This action allows you to assign any purview permission(s) to a user or security group.

## Sample Usage

> *Note: It is preferable to clone or fork this action when testing to avoid populating the actions log for this repo.*

To use the action in a workflow with a service principal for example, you can [create a service principal](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#create-a-service-principal), connect to github and ensure right permissions to successfully run the workflow.

### Ensuring Right Permissions

The identity running the workflow needs to have the following permissions:

- A minimum of the `Contributor` and `User Access Administrator` roles on the subscription containing the purview instance. [See how to assign roles to an identity](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest)

- The identity must also have the `root collection admin` access on the purview instance. [See how to add root collection admin to purview](https://learn.microsoft.com/en-us/cli/azure/purview/account?view=azure-cli-latest#az-purview-account-add-root-collection-admin)

### Sample Workflow

The action can be used directly from your repository source code or published to a marketplace. To publish to a marketplace, create a new repository for the action and follow the instructions on [publishing an action to a marketplace](https://docs.github.com/en/actions/creating-actions/publishing-actions-in-github-marketplace).

A sample workflow looks like the one below:

```yaml
name: Test pipeline

on: [push]

jobs:   
  workflow-test:
    name: 'Set purview permissions with workflow'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: 'Az login'
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Set purview permissions
        uses: <url_to_your_github_action@v1>   # e.g abeebu/purview-custom-permissions@v1 or uses: ./ if you are using the source code in your repository
        with:
          purview_name: "<purview_account_name>"  # as in https://<purview_account_name>.purview.azure.com  
          object_id: "object-id"  # Object Id to assign permissions to
          user_type: "U" # 'U' for user and 'G' for security group
          roles: "data_reader,data_curator,data_share_contributor" # list of roles to assign separated by comma
```

## Supported Roles

The following roles are supported:

- root_collection_admin
- data_reader
- data_curator
- data_source_admin
- data_share_contributor
- workflow_admin
