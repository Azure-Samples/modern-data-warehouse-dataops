# Introduction 

This repo contains the code for establishing a CI/CD process around Fabric workspaces. The code is intended to be used as a jumpstart for a new project on Microsoft Fabric. Currently, there are many limitations, but the goal is to expand the capabilities of the code over time.

Aditionally, some of the REST APIs used in the code of the release pipelines will be available mid-April.
The boostrap code is using already available APIs.

## Deployment Process

### Understanding "bootstrap" script

#### Bootstrap workflow

#### Hydrating Fabric artifacts

### Infrastructure deployment steps

Here are the steps to use the bootstrap script:

- Change the directory to the `scripts` folder:

```bash
cd scripts
```

- Rename the [env.sample](./.env.sample) file to `.env` and fill in the necessary environment variables. Here is the detailed explanation of the environment variables:

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

- Rename the [params.json-template] file to `params.json` and fill in the necessary values. The admin address should be a user in the same tenant where the sample is being deployed.

### Creating CI/CD pipelines

#### Option 1: Using Fabric Deployment Pipelines API

When your Development, Test and Production environments are located in the same tenant, using Fabric Deployment pipelines is a great solution to promote your changes between the environments.

Building on top of the bootstrap and hydration outcomes, there are two options to implement the CD release process in Fabric.
There are two [yml files](./devops/) and you can use the files to create an Azure DevOps pipeline. The first option offers an approval gate before allowing the deployment to Test and to Production. The second option doesn't include the approval gates.

##### Pre-requisites - Variable Groups

Before trunning the CD release pipeline, the following variable groups need to be created under Pipelines/Library in Azure DevOps.

###### fabric-test variable group

The fabric-test group should contain the following variables:

|**Field Name**|**Description/Example of a valid value**|
|--------------|-------------------------|
|**fabricRestApiEndpoint** | https://api.fabric.microsoft.com/v1 |
|**pipelineName** | The name of the deployment pipeline in Fabric |
|**sourceStageName** | The name of the source stage of the deployment. E.g: "Development"|
|**targetStageName** | The name of the target stage of the deployment. E.g: "Test"|
|**targetStageWsName** | The name of the workspace assigned to the target stage of the deployment pipeline.|
|**token** | Until SP are not supported, we use the Bearer token as a variable.|

###### fabric-prod

The fabric-prod group should contain the following variables:

|**Field Name**|**Description/Example of a valid value**|
|--------------|-------------------------|
|**fabricRestApiEndpoint** | https://api.fabric.microsoft.com/v1 |
|**pipelineName** | The name of the deployment pipeline in Fabric |
|**sourceStageName** | The name of the source stage of the deployment. E.g: "Test"|
|**targetStageName** | The name of the target stage of the deployment. E.g: "Production"|
|**targetStageWsName** | The name of the workspace assigned to the target stage of the deployment pipeline.|
|**token** | Until SP are not supported, we use the Bearer token as a variable.|

### How to run the CD release pipeline

To run the CD pipeline, create an Azure DevOps pipeline pointing to the azdo-fabric-cd-release.yml file located in the [devops](./devops/) directory.

Make sure that the token is valid for the run, otherwise the pipeline will fail. For more information refer to [Fabric Token](#passing-the-fabric-bearer-token).

Before you run the pipeline, make sure that the Deployment pipeline exists and that the Development workspace is assigned to the Development Stage of the Pipeline. Additionally, uat and prd workspaces should be assigned to the Test and Production Stages respectively. This steps are automated in the bootstrap script.

![Fabric Deployment Pipelines](./images/dep_pipeline.png)

Shifting gears to Azure DevOps, after you create the pipeline and fill out the variables you can trigger manually the execution.
Triggers can be also defined in alignment with your development workflow requirements. This sample doesn't include triggers at the moment.

The version with approvals, need manual intervention during the run. You will need to manually approve before the pipeline completes.

![Approval_1](./images/manual_approval.png)

![Approval_2](./images/manual_approval_2.png)

![AzDo CD Release pipeline run](./images/azdo_pipeline_execution.png)

Upon completion  both deployment stages: "Deploy to Test" and "Deploy to Production"  in the Azure DevOps pipeline should be successfully completed. To verify if the deployment was successful, navigate to Fabric->Deployment pipelines to verify that all the Fabric artifacts were promoted to Test and to Production.

#### Option 2: Using Fabric REST APIs

ET to fill in

## Known Issues

### Bootstrap script fails after workspace creation

The script is not fully idempotent yet. If you ran the script and it failed after the workspace creation, you might encounter the following error message in the next run:

*Workspace: 'ws-fb-1-e2e-sample-uat' (999999999-9999-4f20-ac52-d8ce297dba31) already exists.
[W] Please verify the attached capacity manually.*

To solve the problem, delete the workspaces and attempt to run the script again, or turn off the flag at the beginning of the bootstrap script by setting create_workspaces="false". Alternatively you can chose to assign the capacities to the workspaces manually.

### Several run attempts might lead to strange errors due to the lack of idempotency

Examples are:

- *[E] {"error":{"code":"Alm_InvalidRequest_WorkspaceHasNoCapacity","pbi.error":{"code":"Alm_InvalidRequest_WorkspaceHasNoCapacity","parameters":{},"details":[],"exceptionCulprit":1}}}[I] Assigned workspace 'ID' to stage '0' successfully.
[I] Workspace ws-fb-1-e2e-sample-uat (ID)*

- *[E] {"requestId":"ID","errorCode":"UnsupportedCapacitySKU","message":"The operation is not supported over the capacity SKU"}*

To solve the problem, attempt a clean run.

### Getting errors on a successful run

We noticed there are some errors thrown during the bootstrap run, but the deployment was completely successful.
If you notice errors like:

*[E] Notebook upload to the workspace failed.
[E] Committing workspace changes to git failed.*

Double check first that the notebook really failed or not, and the same for the Git synchronization.

### Passing the Fabric Bearer Token

You may experience "The token expired." error message. To workaround it, a new token needs to be generated.

A temporary way to get the token can be found in the following [article](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-quickstart#c-code-sample-for-acquiring-a-microsoft-entra-access-token)

For a quick alternative to get a token:

- login into the Fabric portal with the credentials you want to get the token
- Click on F12 - Developer tools
- Click on console
- Type copy(powerBIAccessToken)
- Paste the token into the variables of the pipeline

Bear in mind that this is not a production ready solution. The token needs to be refreshed every hour for the solution to run properly.