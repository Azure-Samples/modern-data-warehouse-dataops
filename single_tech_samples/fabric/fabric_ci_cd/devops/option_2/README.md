# DevOps Pipelines for Option 2

The pipelines provided in this example are currently built using Azure DevOps. 
Nonetheless creating similar pipelines for GitLab and other git tools should be 
straightforward as no Azure DevOps specific functionalities have been employed (except 
for system variables and commands specific to variable groups).

## Variables

The pipelines in this sample depend on the following variable groups:
- `var-group-option-2-common` used for variables that are common to all pipelines
- `var-group-option-2-dev`, `var-group-option-2-stg` and `var-group-option-2-prd` 
used for variable that are specific to, respectively, `dev`,`stg` and `prd` environments.

|<div style="width:200px">**Variable Group**</div>|**Variable Name**|**Description**|
|:---|:---|:---|
|`var-group-option-2-common`|`directoryName`| the value of the directory where Fabric item files (such as `item.config.json`, `item.definition.json`, `item.metadata.json`, and item specific definition files) will be stored|
|`var-group-option-2-common`|`fabricRestApiEndpoint`| the value of the Fabric REST API endpoint, currently `https://api.fabric.microsoft.com/v1`|
|`var-group-option-2-common`|`token`| the user token used to authenticate against the Fabric API endpoint. This is needed until Service Principals will be supported by the Fabric APIs|
||||
|`var-group-option-2-dev`|`workspaceName`| the name of the workspace that should be connected to the `dev` branch|
|`var-group-option-2-dev`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|
||||
|`var-group-option-2-stg`|`workspaceName`| the name of the workspace that should be connected to the `stg` branch|
|`var-group-option-2-stg`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|
Fabric APIs|
||||
|`var-group-option-2-prd`|`workspaceName`| the name of the workspace that should be connected to the `prd` branch|
|`var-group-option-2-prd`|`capacityId`| the Fabric Capacity Id that will be used to assign the workspace `workspaceName` in case of creation|


## Build Pipeline

The step `Check if item.config.json files are modified` in the [build pipeline](ci.yaml) 
contains a step that will make the pipeline fail if the developer is trying to commit any 
`item.config.json` files to the branch. This is to prevent loosing track of the Fabric 
item `objectId`s that have been already created on the Fabric Workspace. Without this 
check a developer might inadvertedly commit to the branch the `objectId`s of his sandbox 
environment. If this happens, existing items that need to be updated would be otherwise 
deleted and re-created from scratch.

## Release Pipeline

The [release pipeline](release_pipeline_option2.yml) currently contains only one stage 
that deploys the changes to the `dev` branch. Other `stg` and `prd` stages can be easily
derived from this stage as they will need to perform very similar actions.

The pipeline starts running the [`update_from_git_to_ws.ps1`](../../src/option_2/update_from_git_to_ws.ps1) 
to reflect in the Fabric DEV workspace the changes that are being committed to the 
`dev` branch.

When the `update_from_git_to_ws.ps1` script will run on the agent, it will produce 
various outputs, including `item.config.json` files that will be stored locally to the 
agent filesystem.

To make sure that any Fabric item `objectId` created by the above step is also tracked 
on the repository, the release pipeline has a second step `Push Config to branch`. This 
step will create a commit to the `dev` branch containing any modified `item.config.json` 
files. 
> Note: For this step to work you will have to make sure that your build 
service can bypass branch policies (such as skipping CI events given it will commit to 
`dev`) as well as making sure the build service is allowed to push changes to your `dev` 
branch.