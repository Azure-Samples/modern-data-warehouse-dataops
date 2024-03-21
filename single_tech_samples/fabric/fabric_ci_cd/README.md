# Introduction 

This repo contains the code for establishing a CI/CD process around Fabric workspaces. The code is intended to be used as a jumpstart for a new project on Microsoft Fabric. Currently, There are many limitations, but the goal is to expand the capabilities of the code over time.

## Deployment Process

### Understanding "bootstrap" script

### Infrastructure deployment steps

Here are the steps to use the bootstrap script:

1. Change the directory to the `scripts` folder:

```bash
cd scripts
```

1. Rename the [env.sample](./.env.sample) file to `.env` and fill in the necessary environment variables. Here is the detailed explanation of the environment variables:

```bash
AZURE_SUBSCRIPTION_ID='Azure Subscription Id'
AZURE_LOCATION='The location where the Azure resources will be created'
RESOURCE_GROUP_NAME='The name of the resource group'
FABRIC_CAPACITY_NAME='The name of the Fabric capacity'
FABRIC_PROJECT_NAME='The name of the Fabric project. This name is used for naming the Fabric resources.'
FABRIC_API_ENDPOINT='The Fabric API endpoint. e.g., https://api.fabric.microsoft.com/v1'
DEPLOYMENT_API_ENDPOINT='The deployment API endpoint. e.g., https://api.powerbi.com/v1.0/myorg/pipelines'
FABRIC_BEARER_TOKEN='The bearer token for calling the Fabric APIs.'
ORGANIZATION_NAME='Azure DevOps organization name'
PROJECT_NAME='Azure DevOps project name'
REPOSITORY_NAME='Azure DevOps repository name'
BRANCH_NAME='Azure DevOps branch name'
DIRECTORY_NAME='The directory used by Fabric to sync the workspace code. Can be "/" or any other sub-directory.'
```

### Creating CI/CD pipelines

#### Option 1: Using Fabric Deployment Pipelines API

When your Development, Test and Production environments are located in the same tenant, using Fabric Deployment pipelines is a great solution to promote your changes between the environments.

Building on top of the bootstrap and hydration outcomes, there are two options to implement the CD release process in Fabric.
There are two [yml files](./src/option_1/) and you can use the files to create an Azure DevOps pipeline. The first option offers an approval gate before allowing the deployment to Test and to Production. The second option doesn't include the approval gates.

##### Pre-requisites - Variable Groups

Before trunning the CD release pipeline, the following variable groups need to be created under Pipelines/Library in Azure DevOps.

###### fabric-test variable group

This group should contain the following variables:

**fabricRestApiEndpoint** - e.g: https://api.fabric.microsoft.com/v1

**pipelineName** - the name of the deployment pipeline in Fabric

**sourceStageName** - name of the source stage of the deployment. E.g: "Development"

**targetStageName** - name of the target stage of the deployment. E.g: "Test"

**targetStageWsName** - name of the workspace assigned to the target stage of the deployment pipeline.

**token** - until SP are not supported, we use the Bearer token as a variable.

####### fabric-prod

This group should contain the following variables:

**fabricRestApiEndpoint** - e.g: https://api.fabric.microsoft.com/v1

**pipelineName** - the name of the deployment pipeline in Fabric

**sourceStageName** - name of the source stage of the deployment. E.g: "Test"

**targetStageName** - name of the target stage of the deployment. E.g: "Production"

**targetStageWsName** - name of the worksapace assigned to the target stage of the deployment pipeline.

**token** - until SP are not supported, the Bearer token as a variable.

### How to run the CD release pipeline

To run the CD pipeline, create an Azure DevOps pipeline pointing to the azdo-fabric-cd-release.yml file.

Make sure that the token is valid for the run, otherwise the pipeline will fail.

Before you run the pipeline, make sure that the Deployment pipeline exists and that the Development workspace is assigned to the Development Stage of the Pipeline. Additionally, uat and prd workspaces should be assigned to the Test and Production Stages respectively. This steps are automated in the bootstrap script.

![Fabric Deployment Pipelines](./images/dep_pipeline.png)

Shifting gears to Azure DevOps, after you create the pipeline and fill out the variables you can trigger the execution. 

The version with approvals, need manual intervention during the run. You will need to manually approve before the pipeline completes.

![Approval_1](./images/manual_approval.png)

![Approval_2](./images/manual_approval_2.png)

![AzDo CD Release pipeline run](./images/azdo_pipeline_execution.png)

Upon completion  both deployment stages: "Deploy to Test" and "Deploy to Production"  in the Azure DevOps pipeline should be successfully completed. To verify if the deployment was successful, navigate to Fabric->Deployment pipelines to verify that all the Fabric artifacts were promoted to Test and to Production.

#### Option 2: Using Fabric REST APIs

ET to fill in

## Known Issues

### Passing the Fabric Bearer Token

This is due to a known limitation that the Fabric APIs don't have Service Principal (SP) support (See [Microsoft Documentation](https://learn.microsoft.com/rest/api/fabric/articles/using-fabric-apis#considerations-and-limitation)). Currently, the script uses the Fabric Bearer Token to authenticate with the Fabric API. 

For now, the token has to be manually generated and passed to the script as an environment variable. This token is valid for 1 hour and needs to be refreshed after that. The token can be generated by using the following PowerShell command:

```powershell
[PS]> Connect-PowerBIServiceAccount
[PS]> Get-PowerBIAccessToken
```

If you are already logged into Fabric portal, you can invoke the following command from the Browser DevTools (F12) console:

```powershell
> copy(PowerBIAccessToken)
```

This would copy the token in your clipboard which you can then add in the .env file.

### Existing Workspace Warning

The script starts by creating a new capacity in Azure. If the capacity already exists, the script will fetch the Id based on the name. The script then tries to create new workspaces and associate them to the capacity.

Now, if the workspaces already exist, the script doesn't attempt to delete and recreate them as it might result in losing data and business logic. Instead, the script writes the following warning message:

```txt
*Workspace: 'ws-fb-1-e2e-sample-uat' (999999999-9999-4f20-ac52-d8ce297dba31) already exists.
[W] Please verify the attached capacity manually.*
```

As stated in the warning message, you might want to review the workspace and assign it to the right capacity manually. You can also choose to either delete the workspaces manually and attempt to run the script again, or turn off the flag at the beginning of the bootstrap script by setting create_workspaces variable to "false".

### Several run attempts might lead to strange errors

Because the scripts relies heavily on the Fabric API, there are a lot of reasons that it might fail. Here are some examples:

```txt
*[E] {"error":{"code":"Alm_InvalidRequest_WorkspaceHasNoCapacity","pbi.error":{"code":"Alm_InvalidRequest_WorkspaceHasNoCapacity","parameters":{},"details":[],"exceptionCulprit":1}}}[I] Assigned workspace '<ID>>' to stage '0' successfully.   
[I] Workspace ws-fb-1-e2e-sample-uat (ID)*

*[E] {"requestId":"<ID>>","errorCode":"UnsupportedCapacitySKU","message":"The operation is not supported over the capacity SKU"}*
```

If you are running into such issue, you might want to add additional debugging information to the script to understand the root cause of the issue. For a fresh start, you might want to delete the capacity and the workspaces and run the script again. An ideal execution of the script should look something like this:

```txt
[I] ############ START ############
[I] ############ Azure Resource Deployment ############
[I] Creating resource group 'rg-fabric-cicd'
[I] Deploying Azure resources to resource group 'rg-fabric-cicd'
[I] Capacity 'capfabriccicd' created successfully.
[I] ############ Workspace Creation ############
[I] Fabric capacity is 'capfabriccicd' (2a76fa8a-ee52-4251-968c-fc7b295fcbc0)
[I] Created workspace 'ws-fabric-cicd-dev' (8978c223-2ec9-4522-a172-073c4604e1f6)
[I] Created workspace 'ws-fabric-cicd-uat' (92d8d07a-ebe8-40ac-928f-bb29b7b7f13c)
[I] Created workspace 'ws-fabric-cicd-prd' (dc30ea98-704f-45e6-b9fd-2d985526da5a)
[I] ############ Deployment Pipeline Creation ############
[I] No deployment pipeline with name 'dp-fabric-cicd' found, creating one.
[I] Created deployment pipeline 'dp-fabric-cicd' (ed946d85-6370-4bc7-b134-af865a4fd1e4) successfully.
[I] Workspace ws-fabric-cicd-dev (8978c223-2ec9-4522-a172-073c4604e1f6)
[I] Existing workspace for stage '0' is .
[I] Assigned workspace '8978c223-2ec9-4522-a172-073c4604e1f6' to stage '0' successfully.
[I] Workspace ws-fabric-cicd-uat (92d8d07a-ebe8-40ac-928f-bb29b7b7f13c)
[I] Existing workspace for stage '1' is .
[I] Assigned workspace '92d8d07a-ebe8-40ac-928f-bb29b7b7f13c' to stage '1' successfully.
[I] Workspace ws-fabric-cicd-prd (dc30ea98-704f-45e6-b9fd-2d985526da5a)
[I] Existing workspace for stage '2' is .
[I] Assigned workspace 'dc30ea98-704f-45e6-b9fd-2d985526da5a' to stage '2' successfully.
[I] ############ Lakehouse Creation (DEV) ############
[I] Created Lakehouse 'lh_main' (51b03016-8a14-4c65-ae9a-ce0743fdfa35) successfully.
[I] ############ Notebooks Creation (DEV) ############
[I] Created Notebook 'nb-city-safety' (ff1a27c2-ea4b-4cbb-91c9-4883afed61fc) successfully.
[I] Created Notebook 'nb-covid-data' (d3fd147a-40ae-40d4-8c95-44cae3a96ac3) successfully.
[I] ############ Data Pipelines Creation (DEV) ############
[I] Created DataPipeline 'pl-covid-data' (3877e187-b966-41a9-a7db-a1113fafc39b) successfully.
[I] ############ Triggering Notebook Execution (DEV) ############
[I] Notebook execution triggered successfully.
[I] ############ Triggering Data Pipeline Execution (DEV) ############
[I] Data pipeline execution triggered successfully.
[I] ############ GIT Integration (DEV) ############
[I] Workspace connected to the git repository.
[I] The Git connection has been successfully initialized.
[I] Committed workspace changes to git successfully.
```
