# Load Testing

## Getting Started

Execute these steps to create the infrastructure:

1. Clone the sample repo
1. Add service connection to Azure subscription
1. Add a variable group
1. Create the Pipeline
1. Check out results in the portal

## Files

The load testing is orchestrated by 3 files.

- **loadtest-pipeline.yml**: This azure pipeline runs the two powershell scripts. You can adjust the load that you want to pass into the `IoTSimulator.ps1` script by changing the variables.
- **IoTSimulator.ps1**: This powershell script is the core. It spins up Azure Container Instances by using the [IoT Simulator](https://github.com/Azure-Samples/Iot-Telemetry-Simulator). It tears down all container instances after sending the load as well.
- **LoadTestCheckResult.ps1**: This powershell script gets the ingress and egress metrics for eventhub, and fails the load testing task if the total egress is smaller that the number of ingress.

## Setup

### 1. Clone the sample repo

The easiest way to get the source code ready for use in a pipeline, is to import the git repo into your Azure DevOps instance.

1. In your Azure Devops instance, go to `repos` -> `files`
1. In the Git repo pulldown, select `import repository` ![Git import](../images/loadtesting_git_import.png?raw=true "import repository")
1. Enter the GitHub repo url e.g. `https://github.com/Azure-Samples/modern-data-warehouse-dataops.git`![Git url](../images/loadtesting_git_import_url.png?raw=true "Git url")

### 2. Add service connection to Azure subscription

An authenticated service connection to your Azure subscription is required, so that your pipeline can access/create resources in your azure subscription. Follow [this documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) to set up the service connection.

1. Go into the service connection page. `Project settings` -> `Pipelines` -> `Service connections` -> `New Service Connection`
1. Create a Service Connection named `sample-dataops`. (You can use another name, if you edit the pipeline in later steps).
1. You do not need to select a Resource Group to scope it to.

### 3. Add a variable group

In the pipeline yaml, we need variables which are stored as secrets in Key Vault. A convenient way is to access the secrets in a pipeline is via a **Variable Group**.

1. Go to Azure DevOps -> Pipelines -> Library: ![azure_pipeline_var_group](../images/azure_pipeline_var_group.png?raw=true)
1. Select your Azure subscription, and the keyvault.
1. Select the following secrets that were populated by terraform:

- *Ingest-conn*: connection string of the entry eventhub.
- *Ingest-name*: name of the entry eventhub.
- *Ingest-namespace*: eventhub namespace of the entry eventhub.
- *rg-name*: name of the resource group.
- *subscription-id*: subscription Id of the project.

 ![var_group_secrets](../images/var_group_secrets.png?raw=true)

### 4. Azure Pipelines

1. `Pipelines` -> `New pipeline` -> `Existing Azure pipelines YAML file` ![azure_pipeline_setup](../images/azure_pipeline_setup.png?raw=true)
1. Manually enter `e2e_samples/temperature_events/loadtesting/loadtest-pipeline.yml`.
1. After creating, click run to run your first load test

#### Pipeline notes: Key Vault secrets

You are able to use Key Vault secrets directly in the pipeline, as the variable group is defined in the `loadtest-pipeline.yml` file

```yaml
variables:
- group: load-testing-secrets
```

#### Pipeline notes: Service connection

The service connection is defined in the pipeline yaml. Change it here if you created under a different name.

```yaml
- name: ServiceConnection
  value: sample-dataops
```

### 5. Check out results in the portal

The load test will have injected a lot of messages to the ingest Event Hub, which are processed by the Azure Function, and passed through the pipeline.

1. Look at the main ReadMe section on [Observability](../README.md#observability).
1. Try Creating your own dashboard in the Azure portal. Check the [Observability](../README.md#observability) section for more details.
1. In your Azure subscription, go into the Application Insights instance. Navigate to the `Application Map` and you should see the Azure Functions consuming and pushing to Event Hubs. Below is an example screenshot. ![Application map](../images/application_map.png?raw=true "Application map")
