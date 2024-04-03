# Fabric CI/CD Sample <!-- omit in toc -->

This repo contains a code sample for establishing a CI/CD process for Microsoft Fabric workspaces. The code is intended to be used as a jump-start for a new project on Microsoft Fabric. At present, the code has several limitations; however, the objective is to continuously improve its capabilities in sync with the advancements of Fabric.

## Contents <!-- omit in toc -->

- [Architecture](#architecture)
- [How to use the sample](#how-to-use-the-sample)
  - [Pre-requisites](#pre-requisites)
  - [Execute bootstrap script](#execute-bootstrap-script)
  - [Fabric CI/CD pipelines](#fabric-cicd-pipelines)
    - [CI process](#ci-process)
    - [CD process - Option 1: Using Fabric Deployment Pipelines API](#cd-process---option-1-using-fabric-deployment-pipelines-api)
    - [CD process - Option 2: Using Fabric REST APIs](#cd-process---option-2-using-fabric-rest-apis)
- [Understanding bootstrap script](#understanding-bootstrap-script)
  - [List of created resources](#list-of-created-resources)
  - [Hydrating Fabric lakehouse](#hydrating-fabric-lakehouse)
    - [Using Fabric notebooks](#using-fabric-notebooks)
    - [Using Fabric data pipelines](#using-fabric-data-pipelines)
- [Known issues](#known-issues)
  - [Passing the Fabric bearer token](#passing-the-fabric-bearer-token)
  - [Existing Workspace Warning](#existing-workspace-warning)
  - [Several run attempts might lead to strange errors](#several-run-attempts-might-lead-to-strange-errors)
- [References](#references)

## Architecture

![Fabric CI/CD Architecture](./images/fabric-cicd.drawio.svg)

## How to use the sample

### Pre-requisites

- Ensure *always* latest Fabric Token is added to the .env file (see instructions below).
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and [jq](https://jqlang.github.io/jq/download/) are installed.
- Ensure that correct Azure account is being used.

### Execute bootstrap script

Here are the steps to use the bootstrap script:

1. Clone the repository:

    ```bash 
    # Optional
    az account set -s "<subscription_id>"
    az login --tenant "<tenant_id>"
    cd "<installation_folder>"
    # Repo clone
    git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git
    ```

1. Change the directory to the sample folder:

    ```bash
    cd ./modern-data-warehouse-dataops/single_tech_samples/fabric/fabric_ci_cd
    ```

1. Rename the [.envtemplate](./.envtemplate) file to `.env` and fill in the necessary environment variables. Here is the detailed explanation of the environment variables:

    ```bash
    AZURE_SUBSCRIPTION_ID='Azure Subscription Id'
    AZURE_LOCATION='The location where the Azure resources will be created'
    CAPACITY_ADMIN_EMAIL='The email address of the Fabric capacity admin. This should be from the same tenant where capacity is being created.'
    FABRIC_PROJECT_NAME='The name of the Fabric project. This name is used for naming the Fabric resources.'
    FABRIC_DOMAIN_NAME="The name of the Fabric domain. It can be an existing domain."
    FABRIC_SUBDOMAIN_NAME="The name of the Fabric subdomain. It can be an existing subdomain."
    FABRIC_BEARER_TOKEN='The bearer token for calling the Fabric APIs.'
    ORGANIZATION_NAME='Azure DevOps organization name'
    PROJECT_NAME='Azure DevOps project name'
    REPOSITORY_NAME='Azure DevOps repository name'
    BRANCH_NAME='Azure DevOps branch name. This branch should already exist in the repository.'
    DIRECTORY_NAME='The directory used by Fabric to sync the workspace code. It can be "/" or any other sub-directory. If specifying a sub-directory, it must exist in the repository.'
    ```

1. Review the various flags in the [bootstrap.sh](./bootstrap.sh) script and set them as needed. Here is a list of the flags:

    | Flag                                | Description                                                           | Default Value | Required Environment  Variables                                                                         | Dependencies |
    | :---------------------------------- | :-------------------------------------------------------------------- | :------------ |  :----------------------------------------------------------------------------------------------------- | :----------- |
    | deploy_azure_resources              | Flag to deploy Azure resources.                                       | `false`       | `AZURE_SUBSCRIPTION_ID`</br>`AZURE_LOCATION`</br>`CAPACITY_ADMIN_EMAIL`                                | None         |
    | create_workspaces                   | Flag to create new Fabric workspaces.                                 | `true`        |  `FABRIC_PROJECT_NAME`                                                                                  | None         |
    | connect_to_git                      | Flag to connect the workspaces to the GIT repository.                 | `false`       | `ORGANIZATION_NAME`</br>`PROJECT_NAME`</br>`REPOSITORY_NAME`</br>`BRANCH_NAME`</br>`DIRECTORY_NAME` | None         |
    | setup_deployment_pipeline           | Flag to create a deployment pipeline and assign workspaces to stages. | `false`       |  `FABRIC_PROJECT_NAME`                                                                                  | None         |
    | create_default_lakehouse            | Flag to create a default Lakehouse.                                   | `false`       |  None                                                                                                   | None         |
    | create_notebooks                    | Flag to create Fabric notebooks.                                      | `false`       |  None                                                                                                   | None         |
    | create_pipelines                    | Flag to create Fabric data pipelines.                                 | `false`       |  None                                                                                                   | None         |
    | trigger_notebook_execution          | Flag to trigger the execution of Fabric notebooks.                    | `false`       |  None                                                                                                   | None         |
    | trigger_pipeline_execution          | Flag to trigger the execution of Fabric data pipelines.               | `false`       |  None                                                                                                   | None         |
    | create_domain_and_attach_workspaces | Flag to create a domain and attach workspaces to it.                  | `true`        | `FABRIC_DOMAIN_NAME`</br>`FABRIC_SUBDOMAIN_NAME`                                                       | None         |

1. Run the bootstrap script:

    ```bash
    ./bootstrap.sh
    ```

Good Luck!

### Fabric CI/CD pipelines

#### CI process

The CI process is not showcased in this repository at present and will be added moving forward.

There are some gaps to achieve the full automation at the moment, namely the lack of support for SPs.

#### CD process - Option 1: Using Fabric Deployment Pipelines API

For the CD process, the Azure DevOps pipelines provided in the sample are meant to be triggered manually, and the trigger can be easily implemented by changing the "trigger:" property in the yml file.

This option is recommended for cases where the Development, Test and Production environments are located in the same tenant. Using Fabric Deployment pipelines is a great solution to promote your changes between the environments.

Building on top of the bootstrap and hydration outcomes, there are two options to implement the CD release process in Fabric. There are two [yml files](./devops/) that can be used to create an Azure DevOps pipeline. The first option offers an approval gate before allowing the deployment to Test and to Production. The second option doesn't include the approval gates.

**1 - Pre-requisites - Variable Groups**: before turning the CD release pipeline, the following variable groups need to be created under Pipelines/Library in Azure DevOps.

**fabric-test variable group**: should contain the following variables:

|**Field Name**|**Description/Example of a valid value**|
|--------------|-------------------------|
|**fabricRestApiEndpoint** | `https://api.fabric.microsoft.com/v1` |
|**pipelineName** | The name of the deployment pipeline in Fabric |
|**sourceStageName** | The name of the source stage of the deployment. E.g: "Development"|
|**targetStageName** | The name of the target stage of the deployment. E.g: "Test"|
|**targetStageWsName** | The name of the workspace assigned to the target stage of the deployment pipeline.|
|**token** | Until SP are not supported, we use the Bearer token as a variable.|

**fabric-prod** : should contain the following variables:

|**Field Name**|**Description/Example of a valid value**|
|--------------|-------------------------|
|**fabricRestApiEndpoint** | `https://api.fabric.microsoft.com/v1` |
|**pipelineName** | The name of the deployment pipeline in Fabric |
|**sourceStageName** | The name of the source stage of the deployment. E.g: "Test"|
|**targetStageName** | The name of the target stage of the deployment. E.g: "Production"|
|**targetStageWsName** | The name of the workspace assigned to the target stage of the deployment pipeline.|
|**token** | Until SP are not supported, we use the Bearer token as a variable.|

**NOTE:** the bootstrap script creates the dev, uat and prd workspaces. Depending on the Project name used in the `.env` file the names of the workspaces might differ. Make sure that the name created in the bootstrap is the same name referred in the variable groups. E.g: ws-fabric-cicd-dev

**2 - Running the release pipeline in Azure DevOps**: to run the CD pipeline, create an Azure DevOps pipeline pointing to the azdo-fabric-cd-release.yml file located in the [devops](./devops/) directory.

Make sure that the token is valid for the run, otherwise the pipeline will fail. For more information refer to [Fabric Token](#passing-the-fabric-bearer-token).

Before you run the pipeline, make sure that the Deployment pipeline exists and that the Development workspace is assigned to the Development Stage of the Pipeline. Additionally, uat and prd workspaces should be assigned to the Test and Production Stages respectively. This steps are automated in the bootstrap script.

![Fabric Deployment Pipelines](./images/dep_pipeline.png)

Shifting gears to Azure DevOps, after you create the pipeline and fill out the variables you can manually trigger the execution.
Triggers can be also defined in alignment with your development workflow requirements. This sample doesn't include triggers at the moment.

The version with approvals, need manual intervention during the run. You will need to manually approve before the pipeline completes.

![Approval_1](./images/manual_approval.png)

![Approval_2](./images/manual_approval_2.png)

![AzDo CD Release pipeline run](./images/azdo_pipeline_execution.png)

Upon completion  both deployment stages: "Deploy to Test" and "Deploy to Production"  in the Azure DevOps pipeline should be successfully completed. To verify if the deployment was successful, navigate to Fabric->Deployment pipelines to verify that all the Fabric artifacts were promoted to Test and to Production.

#### CD process - Option 2: Using Fabric REST APIs

There is a second option to implement the CD release process. This scenario, might be applied in cases when:

- Development, Staging and Production environments are not located in the same tenant.
- Organizations are not using Azure DevOps as a Git tool.

There are some caveats to this approach. The code and more information on this Option, will be available soon.

## Understanding bootstrap script

The bootstrap script is designed to automate the creation of initial Fabric workspaces for a project. The script is written in bash and uses bicep for deploying Azure resources and Fabric REST APIs to create Fabric items and GIT integration.

Here is a summary of the steps that the script performs:

- Creates an Azure resource group and a Fabric capacity. If the capacity already exists, the script fetches the Id based on the capacity name.
- Creates three Fabric workspaces for development (DEV), user acceptance testing (UAT), and production (PRD). If the workspaces already exist, the script fetch the corresponding workspace Ids and writes a warning message to validate that the existing workspaces are indeed connected to the intended capacity.
- Creates a deployment pipeline and assigns the workspaces to the stages. If any pipeline stage is already associated with a different workspace, it reassigns the new workspaces to the stage.
- Creates a Fabric Lakehouse `lh_main`.
- Creates two Fabric notebooks `nb-city-safety` and `nb-covid-data` by uploading the notebook files from the [src/notebooks](./src/notebooks/) directory. If the notebook already exists, the script skips the upload.
- Creates a Fabric data pipeline `pl-covid-data` by uploading the pipeline content from the [src/data-pipelines](./src/data-pipelines/) directory. If the pipeline already exists, the script skips the upload.
- Triggers the execution of the Fabric notebooks and data pipelines to hydrate the Fabric Lakehouse. See [Hydrating Fabric artifacts](#hydrating-fabric-artifacts) for more details.
- Connects the workspaces to the GIT repository and commits the changes. If the workspaces are already connected to the GIT repository, the script leaves it as is.
- Creates the Fabric domain, subdomain or both and attaches the workspaces to it. If the domain and sub-domain already exist, the script attaches the workspaces to the existing ones.
- Finally, all the workspaces changes are committed to the GIT repository.

### List of created resources

Here is a table that lists the resources created by the bootstrap script. `<FABRIC_PROJECT_NAME>` is the variable that is set in the environment file.

|**Resource**|**Description**|**Default Naming**|
|:------------|:---------------|:------------------|
|Resource Group|Azure resource group that contains all the resources.|`rg-<FABRIC_PROJECT_NAME>`|
|Fabric Domain|Fabric domain to which the Fabric workspaces are associated with.|`<FABRIC_DOMAIN_NAME>`|
|Fabric Subdomain|Fabric subdomain to which the Fabric workspaces are associated with.|`<FABRIC_SUBDOMAIN_NAME>`|
|Fabric Capacity|Fabric capacity that contains the Fabric workspaces.|`cap<FABRIC_PROJECT_NAME>`|
|Fabric Workspaces|Three Fabric workspaces that are assigned to the Fabric capacity.|`ws-<FABRIC_PROJECT_NAME>-dev`</br>`ws-<FABRIC_PROJECT_NAME>-uat`</br>`ws-<FABRIC_PROJECT_NAME>-prd`|
|Deployment Pipeline|Fabric deployment pipeline with stages corresponding to the workspaces.|`dp-<FABRIC_PROJECT_NAME>`|
|Fabric Lakehouse|Fabric Lakehouse that contains the data lake.|`lh_main`|
|Fabric Notebooks|Fabric notebooks that contain the business logic.|`nb-city-safety`</br>`nb-covid-data`|
|Fabric Data Pipeline|Fabric data pipelines that contain the data processing logic.|`pl-covid-data`|

### Hydrating Fabric lakehouse

The code samples use [Microsoft open datasets](https://learn.microsoft.com/azure/open-datasets/overview-what-are-open-datasets) and support **parameter driven** executions. The following sections mention the two different ways processing.

#### Using Fabric notebooks

Fabric notebook [nb-city-safety.ipynb](./src/notebooks/nb-city-safety.ipynb) reads data from [Microsoft Open Datasets - city safety data](https://learn.microsoft.com/azure/open-datasets/dataset-new-york-city-safety?tabs=azureml-opendatasets) and populates Lakehouse tables. Here are the key steps:

- Data is extracted for multiple cities, one extract at a time, and loaded into a Lakehouse table.
- Two new columns are added during processing (`UTC time` and `City`).
- Data table load can be configured to run in `overwrite` or `append` mode.
- Count metrics are gathered towards the end of the process.

#### Using Fabric data pipelines

Fabric data pipeline [pl-covid-data](./src/data-pipelines/pl-covid-data-content.json) reads data from [Microsoft Open Datasets - Covid data](https://learn.microsoft.com/azure/open-datasets/dataset-covid-19-data-lake) and populates Lakehouse files. The Pipeline consists of two activities:

1. A `Set variable` activity which has the ability to modify the pipeline parameters and passes these values as 'return values' to next process.
1. A Fabric notebook [nb-covid-data](./src/notebooks/nb-covid-data.ipynb) activity that performs the ETL operations. This is triggered by the success of first activity and uses the 'return values' as input parameters for the execution.

Here are the key steps:

- The target file path is `<Lakehouse>/Files/covid_data/<covid-data-provider-name>/YYYY-MM/YYYY-MM-DD.parquet`.
- Latest (daily) files, at the time of execution are copied from each of the publisher location and stored as `YYYY-MM-DD.parquet`(based on the UTC time ) in the target location.
- Incase of re-runs on the same day, target files will be overwritten.

> *Due to the constraints in creation of linked services using REST APIs, the data pipeline example only includes activities which doesn't have any linked service references.*

## Known issues

### Passing the Fabric bearer token

This is due to a known limitation that the Fabric APIs don't have Service Principal (SP) support (See [Microsoft Documentation](https://learn.microsoft.com/rest/api/fabric/articles/using-fabric-apis#considerations-and-limitation)). Currently, the script uses the Fabric Bearer Token to authenticate with the Fabric API.

For now, the token has to be manually generated and passed to the script as an environment variable. This token is valid for one hour and needs to be refreshed after that. There are several ways to generate the token:

- **Using PowerShell**: The token can be generated by using the following PowerShell command:

    ```powershell
    [PS]> Connect-PowerBIServiceAccount
    [PS]> Get-PowerBIAccessToken
    ```

- **Using browser devtools (F12)**: If you are already logged into Fabric portal, you can invoke the following command from the Browser DevTools (F12) console:

    ```powershell
    > copy(PowerBIAccessToken)
    ```

    This would copy the token in your clipboard that you can update in the .env file.

- **Acquiring the token programmatically**: A programmatic way of acquiring the access token can be found [here](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-quickstart#c-code-sample-for-acquiring-a-microsoft-entra-access-token).

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
[I] ############ Creating (sub)domain attaching workspaces to it ############
[I] Created domain '<FABRIC_DOMAIN_NAME>' (81ef81ae-ca83-4c40-92e4-a7dfa7813824) successfully.
[I] Created subdomain '<FABRIC_SUBDOMAIN_NAME>' (84133035-ba3e-42ca-bd59-6e105f6de69e) successfully.
[I] Assigned workspaces to the (sub)domain successfully.
```

## References

- [Microsoft Fabric REST API documentation](https://learn.microsoft.com/rest/api/fabric/articles/)
- [Introduction to deployment pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)
- [Introduction to Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)
