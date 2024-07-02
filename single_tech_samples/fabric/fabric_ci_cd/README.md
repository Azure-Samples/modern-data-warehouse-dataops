# Fabric CI/CD Sample <!-- omit in toc -->

This repo contains a code sample for establishing a CI/CD process for Microsoft Fabric workspaces. The code is intended to be used as a jump-start for a new project on Microsoft Fabric. At present, the code has several limitations; however, the objective is to continuously improve its capabilities in sync with the advancements of Fabric.

## Contents <!-- omit in toc -->

- [Architecture](#architecture)
- [How to use the sample](#how-to-use-the-sample)
  - [Pre-requisites](#pre-requisites)
  - [Familiarize yourself with known issues, limitations, and workarounds](#familiarize-yourself-with-known-issues-limitations-and-workarounds)
  - [Execute bootstrap script](#execute-bootstrap-script)
  - [Fabric CI/CD pipelines](#fabric-cicd-pipelines)
    - [CI process](#ci-process)
    - [CD process - Using Fabric deployment pipeline APIs](#cd-process---using-fabric-deployment-pipeline-apis)
- [Understanding bootstrap script](#understanding-bootstrap-script)
  - [List of created resources](#list-of-created-resources)
  - [Hydrating Fabric lakehouse](#hydrating-fabric-lakehouse)
    - [Using Fabric notebooks](#using-fabric-notebooks)
    - [Using Fabric data pipelines](#using-fabric-data-pipelines)
- [Alternate approaches for promoting changes to higher environments](#alternate-approaches-for-promoting-changes-to-higher-environments)
  - [Using Fabric GIT APIs only](#using-fabric-git-apis-only)
  - [Using advanced CI/CD sample](#using-advanced-cicd-sample)
- [Other useful utility scripts](#other-useful-utility-scripts)
  - [Python script to upload file in GIT repo to Fabric lakehouse](#python-script-to-upload-file-in-git-repo-to-fabric-lakehouse)
  - [Bash script to update 'token' in AzDo variable group](#bash-script-to-update-token-in-azdo-variable-group)
- [References](#references)

## Architecture

![Fabric CI/CD Architecture](./images/fabric-cicd.drawio.svg)

The architecture diagram above showcases a sample CI/CD process for Microsoft Fabric. The process starts with the bootstrap script that automates the creation of initial Fabric workspaces (Dev, Test, and Prod) for a project. The script creates Azure resources (Fabric capacity), Fabric workspaces, deployment pipelines, Lakehouse, notebooks, data pipelines, and connects the workspaces to the GIT repository. The script also hydrates the Fabric Lakehouse by triggering the execution of the Fabric notebooks and data pipelines. For detailed information about the bootstrap script, see the [Understanding bootstrap script](#understanding-bootstrap-script) section.

As part of the development lifecycle, the developer would create a new "feature" branch out of the "main" branch (the one which is linked to the dev workspace). The developer would also create a private workspace and link it to the "feature" branch. This syncs workspace with the latest code in the "feature" branch. The developer can now make the required changes in this isolated environment. For more details, see the [Develop using another workspace](https://learn.microsoft.com/fabric/cicd/git-integration/manage-branches#develop-using-another-workspace) documentation.

One the changes are made, the developer would commit the changes to the "feature" branch. When the changes are ready to be promoted, the developer would create a pull request to merge the "feature" branch into the "main" branch. The pull request would trigger the Continuous Integration (CI) process that would build, test, and validate the changes. The CI process is not showcased in this repository at present and will be added moving forward, however the CI scope is represented on the architecture diagram for better understanding.

The Continuous Deployment (CD) process is demonstrated using Azure DevOps pipelines. Due to the lack of service principal (SP) support, the Azure DevOps pipelines are required to be triggered manually for now. The CD process is implemented using Fabric deployment pipelines APIs. One of the variant of CD pipelines has the option of approval gates before allowing the deployment to Test and to Production.The CD process includes the creation of variable groups in Azure DevOps and running the release pipeline in Azure DevOps. For more details, see the [Fabric CI/CD pipelines](#fabric-cicd-pipelines) section.

_Note that the private workspace needs to be created manually by the developer for now. There is an upcoming feature in Fabric to automate the creation of private workspaces when a new branch is created. The sample will be updated to include this feature once it is available._

## How to use the sample

### Pre-requisites

- Always ensure the latest Fabric Token is added to the .env file (see [instructions](./issues-limitations-and-workarounds.md#passing-the-fabric-bearer-token) for generating the token).
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) and [jq](https://jqlang.github.io/jq/download/) are installed.
- Ensure that correct Azure account is being used.
- Access to Azure DevOps organization and project.
- An Azure Repo. Currently, only [Git in Azure Repos](https://learn.microsoft.com/azure/devops/user-guide/code-with-git?view=azure-devops) with the _same tenant_ as the Fabric tenant is supported.

### Familiarize yourself with known issues, limitations, and workarounds

Refer to the [know issues, limitations, and workarounds](./issues-limitations-and-workarounds.md) page for details. Reviewing this page is highly recommended to understand the limitations, issues, and challenges you may encounter while building CI/CD pipelines for Fabric. It also provides workarounds and alternative approaches to overcome these challenges. This information will also help you understand why certain approaches are used in the bootstrap script and Azure DevOps pipelines.

### Execute bootstrap script

Here are the steps to use the bootstrap script:

1. Clone the repository:

    ```bash
    # Optional
    az login --tenant "<tenant_id>"
    az account set -s "<subscription_id>"
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
    EXISTING_CAPACITY_NAME="The name of the existing Fabric capacity. This name is required if you want to use an existing capacity instead of creating a new one."
    FABRIC_PROJECT_NAME='The name of the Fabric project. This name is used for naming the Fabric resources.'
    FABRIC_DOMAIN_NAME="The name of the Fabric domain. It can be an existing domain."
    FABRIC_SUBDOMAIN_NAME="The name of the Fabric subdomain. It can be an existing subdomain."
    FABRIC_BEARER_TOKEN='The bearer token for calling the Fabric APIs.'
    ORGANIZATION_NAME='Azure DevOps organization name'
    PROJECT_NAME='Azure DevOps project name'
    REPOSITORY_NAME='Azure DevOps repository name'
    BRANCH_NAME='Azure DevOps branch name. This branch should already exist in the repository.'
    DIRECTORY_NAME='The directory used by Fabric to sync the workspace code. It can be "/" or any other sub-directory. If specifying a sub-directory, it must exist in the repository.'
    WORKSPACE_ADMIN_UPNS='UserPrincipalName (UPN) list of the workspace admins. These users will have admin access to the Fabric workspaces. The values are separated by space.'
    PIPELINE_ADMIN_UPNS='UserPrincipalName (UPN) list of the pipeline admins. These users will have admin access to the Fabric deployment pipeline. The values are separated by space.'
    ```

1. Review the various flags in the [bootstrap.sh](./bootstrap.sh) script and set them as needed. Here is a list of the flags:

    | Flag                                | Description                                                           | Default value | Required environment  variables                                                                         |
    | :---------------------------------- | :-------------------------------------------------------------------- | :------------ |  :----------------------------------------------------------------------------------------------------- |
    | deploy_azure_resources              | Flag to deploy Azure resources.                                       | false         | If set to false:</br>`EXISTING_CAPACITY_NAME`</br>If set to false:</br>`AZURE_SUBSCRIPTION_ID`</br>`AZURE_LOCATION`</br>`CAPACITY_ADMIN_EMAIL`                               |
    | create_workspaces                   | Flag to create new Fabric workspaces.                                 | true          | `FABRIC_PROJECT_NAME`                                                                                  |
    | setup_deployment_pipeline           | Flag to create a deployment pipeline and assign workspaces to stages. | true          | `FABRIC_PROJECT_NAME`                                                                                  |
    | create_default_lakehouse            | Flag to create a default Lakehouse.                                   | true          | -                                                                                                   |
    | create_notebooks                    | Flag to create Fabric notebooks.                                      | true          | -                                                                                                   |
    | create_pipelines                    | Flag to create Fabric data pipelines.                                 | true          | None                                                                                                   |
    | trigger_notebook_execution          | Flag to trigger the execution of Fabric notebooks.                    | true          | -                                                                                                   |
    | trigger_pipeline_execution          | Flag to trigger the execution of Fabric data pipelines.               | true          | -                                                                                                   |
    | should_disconnect                   | Flag to disconnect the workspaces from the GIT repository.            | false         | -                                                                                                   |
    | connect_to_git                      | Flag to connect the workspaces to the GIT repository.                 | true          | `ORGANIZATION_NAME`</br>`PROJECT_NAME`</br>`REPOSITORY_NAME`</br>`BRANCH_NAME`</br>`DIRECTORY_NAME` |
    | create_domain_and_attach_workspaces | Flag to create a domain and attach workspaces to it.                  | false         | `FABRIC_DOMAIN_NAME`</br>`FABRIC_SUBDOMAIN_NAME`                                                       |
    | add_workspace_admins | Flag to add admin(s) to the workspaces.                 | false         | `WORKSPACE_ADMIN_UPNS`                                                      |
    | add_pipeline_admins | Flag to add admin(s) to the deployment pipeline.         | false         | `PIPELINE_ADMIN_UPNS`                                                       |
    | create_azdo_variable_groups | Flag to create Azure DevOps variable groups for each environment and adding variables.         | true         | -                                                       |

    Creating Fabric capacities and domains requires elevated privileges. And for that reason, the flags `deploy_azure_resources` and `create_domain_and_attach_workspaces` are set to `false` by default. If you are a Fabric administrator and wish to create new capacity, domain and/or subdomain, set these flags to `true`.

    Also, the flags `add_pipeline_admins` and `add_workspace_admins` are advanced options which allows you to add multiple admins to the deployment pipeline and workspaces respectively. These flags are set to `false` by default. If you wish to add admins, set these flags to `true` and provide the [UPN](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/plan-connect-userprincipalname#what-is-userprincipalname) of the admins in the `WORKSPACE_ADMIN_UPNS` and `PIPELINE_ADMIN_UPNS` environment variables respectively. Currently, the script only supports adding users as admins; it doesn't support adding Microsoft Entra groups or service principals as admins.

    If you are toggling other flags, make sure to set the required environment variables accordingly and review the script to understand the implications.

1. Run the bootstrap script:

    ```bash
    ./bootstrap.sh
    ```

    The script is designed to be idempotent. Running the script multiple times will not result in duplicate resources. Instead, it will either skip or update existing resources. The only exception is when Azure DevOps variable groups which are deleted and recreated. However, it is recommended to review both the script and the created resources to ensure everything is as expected.

Good Luck!

### Fabric CI/CD pipelines

#### CI process

The CI process is not showcased in this repository at present and will be added moving forward, however the CI scope is represented on the architecture diagram for better understanding.

There are some gaps to achieve the full automation at the moment, namely the lack of support for SPs.

#### CD process - Using Fabric deployment pipeline APIs

For the CD process, the Azure DevOps pipelines provided in the sample are meant to be triggered manually, and the trigger can be easily implemented by changing the "trigger:" property in the yml file.

It is important to refer, that despite of the current repository being located on GitHub, the user will need a second repository on Azure DevOps to synchronize the Fabric artifacts definitions - this is because the git integration with Fabric is solely working for Azure DevOps at the moment. As the CD piece is not yet fully automated, a possibility is to copy the entire devops folder to your Azure DevOps repository beside the Fabric artifacts. After the copy, the Azure repo folder structure should look like this:

```bash
├── devops
│   ├── devops_scripts
│   │   ├── run-deployment-pipelines.ps1
│   │   ├── update-workspace-from-git.ps1
│   ├── azdo-fabric-cd-release-with-approvals.yml
│   ├── azdo-fabric-cd-release.yml
├── <DIRECTORY_NAME>
│   ├── <Fabric artifacts would be synced here>
├── ...
```

Here, `DIRECTORY_NAME` is the directory where the Fabric artifacts are stored. This is the same directory that is specified as an environment variable in the [.envtemplate](./.envtemplate) file. The [devops](./devops/) folder contains the Azure DevOps pipeline files. Within devops, the [devops_scripts](./devops/devops_scripts/) folder contains the PowerShell script that triggers the Fabric deployment pipelines.

The bootstrap script creates Azure DevOps variable groups for each environment and adds the required variables. Here are the details about the variable groups, variables, and their default values:

- Variable group for "Development" environment: **vg-<FABRIC_PROJECT_NAME>-dev**

  ```text
  fabricRestApiEndpoint    Fabric Rest API endpoint               https://api.fabric.microsoft.com/v1
  workspaceName            Fabric workspace name                  ws-<FABRIC_PROJECT_NAME>-dev
  workspaceId              Fabric workspace Id                    derived in bootstrap script
  token                    Fabric bearer token                    <FABRIC_BEARER_TOKEN>
  pipelineName             Fabric deployment pipeline name        dp-<FABRIC_PROJECT_NAME>
  mainLakehouseName        Main Lakehouse name                    lh_main
  mainLakehouseId          Main Lakehouse Id                      derived in bootstrap script
  ```

- Variable group for "Test" environment: **vg-<FABRIC_PROJECT_NAME>-uat**

  ```text
  fabricRestApiEndpoint    Fabric Rest API endpoint               https://api.fabric.microsoft.com/v1
  workspaceName            Fabric workspace name                  ws-<FABRIC_PROJECT_NAME>-uat
  workspaceId              Fabric workspace Id                    derived in bootstrap script
  token                    Fabric bearer token                    <FABRIC_BEARER_TOKEN>
  pipelineName             Fabric deployment pipeline name        dp-<FABRIC_PROJECT_NAME>
  mainLakehouseName        Main Lakehouse name                    lh_main
  sourceStageName          Deployment source stage name           Development
  targetStageName          Deployment target stage name           Test
  sourceStageWorkspaceName Deployment source stage workspace name ws-<FABRIC_PROJECT_NAME>-dev
  sourceStageWorkspaceId   Deployment source stage workspace Id   derived in bootstrap script
  ```

- Variable group for "Production" environment: **vg-<FABRIC_PROJECT_NAME>-prd**

  ```text
  fabricRestApiEndpoint    Fabric Rest API endpoint               https://api.fabric.microsoft.com/v1
  workspaceName            Fabric workspace name                  ws-<FABRIC_PROJECT_NAME>-prd
  workspaceId              Fabric workspace Id                    derived in bootstrap script
  token                    Fabric bearer token                    <FABRIC_BEARER_TOKEN>
  pipelineName             Fabric deployment pipeline name        dp-<FABRIC_PROJECT_NAME>
  mainLakehouseName        Main Lakehouse name                    lh_main
  sourceStageName          Deployment source stage name           Test
  targetStageName          Deployment target stage name           Production
  sourceStageWorkspaceName Deployment source stage workspace name ws-<FABRIC_PROJECT_NAME>-dev
  sourceStageWorkspaceId   Deployment source stage workspace Id   derived in bootstrap script
  ```

Please note that if you have skipped the creation of above variable groups in the bootstrap script (Flag `create_azdo_variable_groups` set to false), you will need to create them manually in Azure DevOps and add the variables as mentioned above. Please refer to the [Azure DevOps documentation](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=classic) for details.

Also, make sure that the token is still valid for the run, otherwise the pipeline will fail. For more information refer to [Fabric Token](./issues-limitations-and-workarounds.md#passing-the-fabric-bearer-token). For a utility script to update the token in Azure DevOps variable group, refer to the [following](#bash-script-to-update-token-in-azdo-variable-group) section.

With that, you are now ready to create and run the CD pipelines in Azure DevOps. Follow the below steps:

- Create an Azure DevOps pipeline and copy the content from the [azdo-fabric-cd-release.yml](./devops/azdo-fabric-cd-release.yml) file located in the [devops](./devops/) directory into the AzDO pipeline. Note that there is also a variant of the pipeline with approvals, [azdo-fabric-cd-release-with-approvals.yml](./devops/azdo-fabric-cd-release-with-approvals.yml), that includes approval gates before allowing the deployment to Test and to Production. You can choose the pipeline that best fits your requirements.
- Update the name of the variable groups for each stage. For example, for the "deploy_to_test" stage, use the variable group `vg-<FABRIC_PROJECT_NAME>-uat`. Similarly, for the "deploy_to_production" stage, use the variable group `vg-<FABRIC_PROJECT_NAME>-prd`.
- Before you run the pipeline, make sure that the deployment pipeline exists and that the development workspace is assigned to the "Development" stage of the pipeline. Similarly, uat and prd workspaces should be assigned to the "Test" and "Production" stages respectively. This steps are automated in the bootstrap script.

![Fabric Deployment Pipelines](./images/dep_pipeline.png)

Now you can manually trigger the execution. Triggers can be also defined in alignment with your development workflow requirements. This sample doesn't include triggers at the moment because of the dependency on the bearer token (The token expires after one hour).

The version with approvals, need manual intervention during the run. You will need to manually approve before the pipeline completes.

![Approval_1](./images/manual_approval.png)

![Approval_2](./images/manual_approval_2.png)

![AzDo CD Release pipeline run](./images/azdo_pipeline_execution.png)

Once the execution is complete, both deployment stages, "Deploy to Test" and "Deploy to Production", in the Azure DevOps pipeline should be successful. To verify if the deployment was successful, navigate to Fabric -> Deployment pipelines to verify that all the Fabric artifacts were promoted to "Test" and to "Production" stages.

## Understanding bootstrap script

The bootstrap script is designed to automate the creation of initial Fabric workspaces for a project. The script is written in bash and uses bicep for deploying Azure resources and Fabric REST APIs to create Fabric items and GIT integration.

Here is a summary of the steps that the script performs:

- Creates an Azure resource group and a Fabric capacity. For using an existing capacity, set `deploy_azure_resources` to `false` and provide the existing capacity name using `EXISTING_CAPACITY_NAME` environment variable.
- Creates three Fabric workspaces for development (DEV), user acceptance testing (UAT), and production (PRD). If the workspaces already exist, the script fetch the corresponding workspace Ids and writes a warning message to validate that the existing workspaces are indeed connected to the intended capacity.
- Creates a deployment pipeline and assigns the workspaces to the stages. If any pipeline stage is already associated with a different workspace, it reassigns the new workspaces to the stage.
- Creates a Fabric Lakehouse `lh_main`.
- Creates two Fabric notebooks `nb-city-safety` and `nb-covid-data` by uploading the notebook files from the [src/notebooks](./src/notebooks/) directory. If the notebook already exists, the script skips the upload.
- Creates a Fabric data pipeline `pl-covid-data` by uploading the pipeline content from the [src/data-pipelines](./src/data-pipelines/) directory. If the pipeline already exists, the script skips the upload.
- Triggers the execution of the Fabric notebooks and data pipelines to hydrate the Fabric Lakehouse. See [Hydrating Fabric artifacts](#hydrating-fabric-artifacts) for more details.
- Connects the workspaces to the GIT repository and commits the changes. If the workspaces are already connected to the GIT repository, the script leaves it as is.
- All the workspaces changes are committed to the GIT repository.
- Creates the Fabric domain, subdomain or both and attaches the workspaces to it. If the domain and sub-domain already exist, the script attaches the workspaces to the existing ones.
- Add workspace admins and deployment pipeline admins to the workspaces and deployment pipeline respectively. If the admins are already added, the script skips the addition.
- Create Azure DevOps variable groups for each environment and add the required variables. If the variable groups are already present, it deletes and recreates them.

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
|AzDo Variable Groups|Azure DevOps variable groups for each environment.|`vg-<FABRIC_PROJECT_NAME>-dev`</br>`vg-<FABRIC_PROJECT_NAME>-uat`</br>`vg-<FABRIC_PROJECT_NAME>-prd`|

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

1. A `Set variable` activity which has the ability to modify the pipeline parameters and passes these values as "return values" to next process.
1. A Fabric notebook [nb-covid-data](./src/notebooks/nb-covid-data.ipynb) activity that performs the ETL operations. This is triggered by the success of first activity and uses the "return values" as input parameters for the execution.

Here are the key steps:

- The target file path is `<Lakehouse>/Files/covid_data/<covid-data-provider-name>/YYYY-MM/YYYY-MM-DD.parquet`.
- Latest (daily) files, at the time of execution are copied from each of the publisher location and stored as `YYYY-MM-DD.parquet`(based on the UTC time ) in the target location.
- Incase of re-runs on the same day, target files will be overwritten.

> *Due to the constraints in creation of linked services using REST APIs, the data pipeline example only includes activities which doesn't have any linked service references.*

## Alternate approaches for promoting changes to higher environments

### Using Fabric GIT APIs only

If you don't want to use the Fabric deployment pipelines for continuous delivery (CD), you can use the Fabric Git integration APIs and the GitFlow branching strategy to promote changes to higher environments. In this approach, each workspace is attached to a specific branch in the Git repository. To promote changes to higher environments, a new pull request is raised. When the changes are merged into the target branch, an Azure DevOps pipeline is triggered, which updates the target workspace from Git. The following diagram illustrates this process:

![alternate-approach-1.svg](./images/gitflow-based-deployment.svg)

In the above diagram, there are three workspaces (ignoring 'private' workspaces), and each is linked to a different branch in the Git repository. The CI process remains the same where developers create their own 'Feature' branches and attach those branches to their 'private' workspaces. When the changes are ready to be promoted to the DEV workspace, a pull request is raised from the 'Feature' branch to the 'Main-Dev' branch. When the pull request is merged, an Azure DevOps pipeline is triggered, which updates the DEV workspace from the 'Main-Dev' branch. The same process is followed to promote the changes to the TEST and PROD workspaces. The changes are merged into the 'Main-Test' and 'Main-Prod' branches via PRs, and the corresponding Azure DevOps pipelines are triggered to update the TEST and PROD workspaces respectively using Fabric GIT APIs.

Please note that this approach is conceptual at this stage and not yet implemented in the sample. It has been included here to provide the audience with an alternative approach. Also, it's not really a continuous deployment process as the deployment is based on PR merges and not on code commits.

### Using advanced CI/CD sample

This sample provides a basic CI/CD process for Fabric. Currently, only Git in Azure Repos with the same tenant as the Fabric tenant is supported. Additionally, the sample relies on Fabric deployment pipelines for promoting changes to higher environments.

While this sample may suffice for many organizations, there are scenarios where a more advanced CI/CD process is needed. Some of these scenarios include:

- Your organization adopts multi-tenancy in their CI/CD processes, with different environments (such as development, staging, and production) on different Microsoft Entra IDs.
- Your organization's preferred Git tool is not yet supported by Fabric (e.g., GitLab, Bitbucket).

The [advanced Fabric CI/CD sample](./../fabric_cicd_gitlab/README.md) offers a unique approach for addressing these scenarios. This sample utilizes the Fabric REST APIs for creating and updating Fabric items. It extracts the item metadata and definitions (where applicable) and stores them in a Git repository. A configuration file is used to track the Fabric item Object IDs, preventing the need for constant deletion and recreation of modified items.

## Other useful utility scripts

### Python script to upload file in GIT repo to Fabric lakehouse

For config-driven data pipelines or notebooks, the config files are generally stored in the "Files" section of the Fabric Lakehouse. However, the Git integration with Fabric only syncs the lakehouse metadata, not the actual data files. Therefore, the config files must be version controlled outside of Fabric and uploaded to the lakehouse manually. Including this process in the CI/CD pipeline ensures that the latest config files are always available in the lakehouse, and can be promoted to the higher environments.

To facilitate that, the python script [upload-file-to-lakehouse.py](./scripts/lakehouse-file-upload/upload-file-to-lakehouse.py) uploads a file from a GIT repository to a Fabric lakehouse. The script uses a service principal with a client secret and uses Azure Data Lake APIs to authenticate and upload the file.

We plan to use this script in the future to automate the process of uploading "config" files from the Git repository to the Fabric Lakehouse as part of the CI/CD process.

### Bash script to update 'token' in AzDo variable group

As you may have noticed, the Azure DevOps pipelines mentioned above take Fabric token as a variable. If this token is expired, the pipelines will fail. To avoid this, the token must be updated in the Azure DevOps variable group before pipeline execution. And this is a manual process for now.

To automate this process to some extent, you can use the [update-token-to-azdo-variable.sh](./scripts/update-token-to-azdo-variable/update-token-to-azdo-variable.sh) script. This is a generic Bash script that performs the following actions:

- Prompts the user to run `az login` interactively and generates the Fabric bearer token with the appropriate scope.
- Adds or updates the "token" variable in the Azure DevOps variable group, marking it as "secret".

You can modify this script to update the "token" variable in your Azure DevOps variable group(s) by running it before triggering the Azure DevOps pipeline. It is recommended that this script be run by a user with the "Fabric administrator" role and "Edit" permissions on the Azure DevOps variable group(s).

## References

- [Microsoft Fabric REST API documentation](https://learn.microsoft.com/rest/api/fabric/articles/)
- [Introduction to deployment pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)
- [Introduction to Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)
