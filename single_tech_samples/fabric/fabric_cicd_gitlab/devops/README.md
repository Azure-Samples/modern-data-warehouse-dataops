# DevOps Pipelines

The pipelines provided in this example are currently built using Azure DevOps or GitLab.
Nonetheless creating similar pipelines for Bitbucket or other git tools should be
straightforward.

## Azure DevOps

### Variables

The Azure DevOps pipelines in this sample depend on the following variable groups:

- `var-group-option-2-common` used for variables that are common to all pipelines
- `var-group-option-2-dev`, `var-group-option-2-stg` and `var-group-option-2-prd` are used for variables that are specific to, respectively, `dev`,`stg` and `prd` environments.

The below table contains a description of the variables that have to be defined in the respective variable groups.

|**Variable Group**|**Variable Name**|**Description**|
|:---|:---|:---|
|`var-group-option-2-common`|`directoryName`| the value of the directory where Fabric item files (such as `item-config.json`, `item-definition.json`, `item-metadata.json`, and item specific definition files) will be stored|
|`var-group-option-2-common`|`fabricRestApiEndpoint`| the value of the Fabric REST API endpoint, currently `https://api.fabric.microsoft.com/v1`|
|`var-group-option-2-common`|`token`| the user token used to authenticate against the Fabric API endpoint. This is needed until Service Principals will be supported by the Fabric APIs. \\\n **IMPORTANT**: you should toggle the secret variable type for this variable. |
||||
|`var-group-option-2-dev`|`workspaceName`| the name of the workspace that should be connected to the `dev` branch|
|`var-group-option-2-dev`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|
||||
|`var-group-option-2-stg`|`workspaceName`| the name of the workspace that should be connected to the `stg` branch|
|`var-group-option-2-stg`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|
||||
|`var-group-option-2-prd`|`workspaceName`| the name of the workspace that should be connected to the `prd` branch|
|`var-group-option-2-prd`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|

> Note: If you are using a multi-tenant approach where `dev`, `stg` and `prd` environments are located in different
Entra tenants, then the variable `token` needs to be deleted from the common group and replicated through `dev`, `stg`
and `prd` variable groups as the tokens are going to be different. Furthermore, the respective devops pipeline yml files
will need to point to the right token depending on the target environment (`stg` or `prd`).

### Build Pipeline

The step `Check if item-config.json files are modified` in the [build pipeline](./azure_devops/ci.yaml)
will make the pipeline fail if the developer is trying to commit any `item-config.json`
files to the branch. This is to prevent loosing track of the Fabric item `objectId`s that
have been already created on the Fabric Workspace. Without this check a developer might
inadvertedly commit to the branch the `objectId`s of his sandbox environment. If this
happens, existing items that need to be updated would be otherwise deleted and re-created
from scratch.

### Release Pipeline

The [release pipeline](./azure_devops/release_pipeline.yml) currently contains only one stage
that deploys the changes to the `dev` branch. Other `stg` and `prd` stages can be easily
derived from this stage as they will need to perform very similar actions.

The pipeline starts running the [`update_from_git_to_ws.ps1`](../src/update_from_git_to_ws.ps1)
to reflect in the Fabric DEV workspace the changes that are being committed to the
`dev` branch.

When the `update_from_git_to_ws.ps1` script will run on the agent, it will produce
various outputs, including `item-config.json` files that will be stored locally to the
agent filesystem.

To make sure that any Fabric item `objectId` created by the above step is also tracked
on the repository, the release pipeline has a second step `Push Config to branch`. This
step will create a commit to the `dev` branch containing any modified `item-config.json`
files.
> Note: For this step to work you will have to make sure that your build
service can bypass branch policies (such as skipping CI events given it will commit to
`dev`) as well as making sure the build service is allowed to push changes to your `dev`
branch.

## GitLab

### Variables

The [GitLab CI Pipeline](./gitlab/.gitlab-ci.yml) depends on the following variables.

|**Variable Name**|**Description**|
|:---|:---|
|`GIT_SSH_PRIV_KEY` | the SSH private key used to commit config files from agent |
|`directoryName`| the value of the directory where Fabric item files (such as `item-config.json`, `item-definition.json`, `item-metadata.json`, and item specific definition files) will be stored|
|`fabricRestApiEndpoint`| the value of the Fabric REST API endpoint, currently `https://api.fabric.microsoft.com/v1`|
|`token`| the user token used to authenticate against the Fabric API endpoint. This is needed until Service Principals will be supported by the Fabric APIs.|
|`workspaceName`| the name of the workspace that should be connected to the `dev` branch|
|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|

### Build Job

The `build-job` is triggered whenever a merge request is issued to another branch. The
job will fail (blocking merging to the destination branch) if the developer is trying
to commit any `item-config.json` files to the branch. This is to prevent loosing track
of the Fabric item `objectId`s that have been already created on the Fabric Workspace.
Without this check a developer might inadvertedly commit to the branch the `objectId`s of
his sandbox environment. If this happened, existing items that needed to be updated would
be otherwise deleted and re-created from scratch.

### Release Job

The `deploy-to-dev` is executed whenever a merge request to main is approved.

We only provide one sample release job, the other jobs pushing to staging and production
can be identical or variations depending on your CI/CD strategy.

Here's a breakdown of what `deploy-to-dev` does:

1. **Runner Image**: The pipeline uses the `mcr.microsoft.com/powershell:alpine-3.17` Docker
image as its runner environment.

2. **Before Script**: This section prepares the environment for the pipeline:
   - It checks if `git` and `ssh-agent` are installed, and if not, it installs them.
   - It starts the `ssh-agent` and adds the private SSH key stored in the
   `GIT_SSH_PRIV_KEY` environment variable.
   - It sets the global `git` username and email to the values of `GITLAB_user` and
   `GITLAB_USER_EMAIL` environment variables respectively.
   - It creates a `.ssh` directory, sets the appropriate permissions, and adds
   `gitlab.com` to the `known_hosts` file to allow SSH connections.

   > **Note 1**: in order to allow our GitLab runner to commit back to your repository,
   you will need to configure [Deploy Keys](https://docs.gitlab.com/ee/user/project/deploy_keys/)
   for your GitLab project, adding a Project Deploy Key with **read-write** permissions
   to the project. The `GIT_SSH_PRIV_KEY` project variable will contain the ssh private
   key of the key-pair you will need to generate. For a detailed example you can refer
   to this GitLab blog post: [GitBot – automating boring Git operations with CI](https://about.gitlab.com/blog/2017/11/02/automating-boring-git-operations-gitlab-ci/).
   >
   > **Note 2**: the last step of the before script is prone to Man-In-The-Middle (MITM)
   attacks as it gets the known hosts by asking directly to gitlab.com. With a MITM you
   might receive a fingerprint of a malicious server. To avoid this, you should manually
   verify that the fingerprint returned by the `ssh-keyscan` operation actually matches
   the official GitLab.com fingerprint.

3. **Script**: This section contains the main tasks of the pipeline:
   - It clones your GitLab repository, and checks out the `main` branch
   - It runs the PowerShell script `update_from_git_to_ws.ps1` using project variables
   as the parameters.
   - It checks if the execution of the PowerShell script has generated any config files.
   If there are no changes, it exits the job.
   - If there are changes, it commits them with a specific message (skipping the build
   validation job), and pushes them to the origin.
