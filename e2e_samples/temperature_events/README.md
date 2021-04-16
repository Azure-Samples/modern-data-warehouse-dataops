# DataOps - Temperature Events Demo <!-- omit in toc -->

The sample demonstrates how Events can be processed in a streaming serverless pipeline, while using Observability and load testing to provide insight into performance capabilities.

## Contents <!-- omit in toc -->

- [Solution Overview](#solution-overview)
  - [Architecture](#architecture)
  - [Technologies used](#technologies-used)
- [How to use the sample](#how-to-use-the-sample)
  - [Setup and Deployment](#setup-and-deployment)
  - [Prerequisites](#prerequisites)
  - [Deployed Resources](#deployed-resources)
- [Well Architected Framework (WAF)](#well-architected-framework-waf)
  - [Cost Optimisation](#cost-optimisation)
  - [Operational Excellence](#operational-excellence)
  - [Performance Efficiency](#performance-efficiency)
  - [Reliability](#reliability)
  - [Security](#security)
- [Key Learnings](#key-learnings)
  - [1. Observability is a critical prerequisite, to achieving performance](#1-observability-is-a-critical-prerequisite-to-achieving-performance)
  - [2. Load testing needs representative ratios to test pipeline processing](#2-load-testing-needs-representative-ratios-to-test-pipeline-processing)
  - [3. Validate test data early](#3-validate-test-data-early)
  - [4. Have a CI/CD pipeline](#4-have-a-cicd-pipeline)
  - [5. Secure and centralize configuration](#5-secure-and-centralize-configuration)
  - [6. Make your streaming pipelines replayable and idempotent](#6-make-your-streaming-pipelines-replayable-and-idempotent)
  - [7. Ensure data transformation code is testable](#7-ensure-data-transformation-code-is-testable)
- [Azure Function logic](#azure-function-logic)
  - [Device Filter](#device-filter)
  - [Temperature Filter](#temperature-filter)
- [EventHub & Azure Function scaling](#eventhub--azure-function-scaling)
- [Infrastructure as Code](#infrastructure-as-code)
  - [Modularize Terraform](#modularize-terraform)
  - [Isolation of Environment](#isolation-of-environment)
- [Observability](#observability)
  - [Showing metrics on Azure dashboard](#showing-metrics-on-azure-dashboard)
  - [Application Insights](#application-insights)
    - [Application Map](#application-map)
    - [Azure Function Scaling](#azure-function-scaling)
    - [Distributed Tracing](#distributed-tracing)
    - [End-to-End Transaction Detail](#end-to-end-transaction-detail)
- [Load testing](#load-testing)
  - [Load testing architecture](#load-testing-architecture)

---------------------

## Solution Overview

The solution receives a stream of readings from IoT devices within buildings. These IoT devices are sending values for different sensors and events (e.g. temperature readings, movement senors, door triggers) to indicate the state of a room and building. This streaming pipeline demonstrates how serverless functions can be utilised to filter, process, and split the stream. As this is a stream processing platform, performance is critical to ensure that processing does not 'fall behind' the rate that new events are sent. [Observability](#observability) is implemented to give visibility into the performance of the system to indicate if the system is performing. Load testing is combined with observability to give an indication of system capability under load. The entire infrastructure deployment is orchestrated via Terraform.

### Architecture

The following shows the overall architecture of the solution.

![Architecture](images/temperature-events-architecture.png?raw=true "Architecture")

Message payload
Field name | Description
-- | --
deviceId | Device ID
temperature | temperature reading sensor
time | timestamp of value

### Technologies used

It makes use of the following azure services:

- [Azure Event Hubs](https://azure.microsoft.com/en-us/services/event-hubs/)
- [Azure Functions](https://azure.microsoft.com/en-us/services/functions/)
- [Azure IoT Device Telemetry Simulator](https://github.com/Azure-Samples/Iot-Telemetry-Simulator/)
- [Azure DevOps](https://azure.microsoft.com/en-au/services/devops/)
- [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Terraform](https://www.terraform.io/)

## How to use the sample

> **IMPORTANT NOTE:** As with all Azure Deployments, this will **incur associated costs**. Remember to teardown all related resources after use to avoid unnecessary costs. See [here](#deployed-resources) for list of deployed resources.

### Setup and Deployment

There are 3 major steps to running the sample. Follow each sub-page in order:

1. [Deploy the infrastructure with Terraform](infra/README.md)
1. [Deploy the Azure Function logic](functions/README.md)
1. [Run the load testing script](loadtesting/README.md)

### Prerequisites

- Accounts
  - [Github account](https://github.com/) [Optional]
  - [Azure Account](https://azure.microsoft.com/en-au/free/)
    - *Permissions needed*: ability to create and deploy to an azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview), a [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals), and grant the [collaborator role](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to the service principal over the resource group.
  - [Azure DevOps Project](https://azure.microsoft.com/en-us/services/devops/)
    - *Permissions needed*: ability to create [service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml), [pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops&tabs=yaml) and [variable groups](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml).
- Software
  - [Azure CLI 2.18+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
  - [Terraform 0.14+](https://learn.hashicorp.com/tutorials/terraform/install-cli)
  - [Azure Functions core tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) [Optional]

### Deployed Resources

After a successful deployment, you should have the following resources:

- Resource group 1 (Terraform state & secrets storage)
  - Azure Key Vault
  - Storage account
- Resource group 2 (Temperature Events sample)
  - Application insights
  - Azure Key Vault
  - Event Hub x4
  - Azure Function x2

## Well Architected Framework (WAF)

The [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/) is a set of guiding tenets that can be used to improve the quality of a workload. The framework consists of five pillars of architecture excellence: Cost Optimization, Operational Excellence, Performance Efficiency, Reliability, and Security.
This sample has been built while considering each of the pillars.

### Cost Optimisation

- Scalable costs + Pay for consumption:
  - The technologies used in the sample, are able to start small and then be scaled up as loads increase. Reduce costs when volumes are low.
- Event Hubs:
  - Have been placed together into an Event Hub namespace to pool resources.
  - At higher loads when much higher TUs are required, they can be moved into individual namespaces to reduce TU contention. Or be moved to [Azure Event Hubs Dedicated](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-dedicated-overview)
- Azure Functions:
  - Defined as "Serverless" to reduce cost when developing and experimenting at low data volumes.
  - When moving to higher volume "production loads", the App Service Plan can be changed to using dedicated instances.
  - See [Azure Docs - Azure App Service plan overview](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans) for more information.

### Operational Excellence

Covers the operations processes that keep an application running in production.

- Observability:
  - The sample connects monitoring tools, to give insights such as distributed tracing, application maps, etc. Allowing insights on how the streaming pipeline is performing.
  - See the section on [Observability](#observability)
- Infrastructure Provisioning:
  - IaC (Infrastructure as Code) is used here to provision and deploy the infrastructure to Azure. A Terraform template is used to orchestrate the creation of resources.
- Code Deployment:
  - Deployment pipelines are defined to push application logic to the Azure Function instances.
- Load testing:
  - The load testing process here is defined as a script that can be run in an automated and repeatable way.
  - See  the section on [Load Testing](#load-testing)

### Performance Efficiency

- Performance Limitations
  - [Azure Functions scale limits](https://docs.microsoft.com/en-us/azure/azure-functions/functions-scale#service-limits)
  - [Azure Event Hubs quotas and limits](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-quotas)
- Scaling
  - [Azure Functions Scalability Best Practices](https://docs.microsoft.com/en-us/azure/azure-functions/functions-best-practices#scalability-best-practices)
  - [Scaling Out Azure Functions With Event Hubs Effectively | by Masayuki Ota](https://medium.com/swlh/consideration-scaling-out-azure-functions-with-event-hubs-effectively-5445cc616b01)
  - [Scaling Out Azure Functions With Event Hubs Effectively 2 | by Masayuki Ota](https://masayukiota.medium.com/scaling-out-azure-functions-with-event-hubs-effectively-2-55d143e2b793)
  - [Processing 100,000 events/s with Azure Functions + Event Hubs](https://azure.microsoft.com/en-us/blog/processing-100-000-events-per-second-on-azure-functions/)
- Bottlenecks
  - _TODO: limits from partitions or TPUs?_
  - [Optimising Azure Functions & Event Hubs batch sizes for throughput](https://medium.com/@iizotov/azure-functions-and-event-hubs-optimising-for-throughput-549c7acd2b75)
  - _TODO: AMQP vs HTTPS on EventHubs?_
- Peak Load Testing
  - _TODO: Peak loads for the testing tool_
  - _TODO: Peak loads for the platform?_

### Reliability

- Resiliancy in Architecture
  - The key resiliency aspects are created through a queue based architecture.  For queues the architecture is leveraging Azure Event Hubs which is highly reliable, with high availability and [geo-redundancy](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-geo-dr).
- Reliability allowance for scalability and performance
  - Azure Event Hubs and Azure Functions scale well.  However for optimal performance they can (and should) be tuned for your platform behaviours.
  - [Event Hubs Scaling](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-scalability#partitions)

### Security

- Secrets, connection strings, and other environmental variables are stored in Azure Key Vault. This prevents accidental leaking or committing secrets into a codebase. [Azure docs - About Azure Key Vault secrets](https://docs.microsoft.com/en-us/azure/key-vault/secrets/about-secrets)
- Access to Event Hubs are restricted via SAS tokens. Only services that hold the Shared Access Signature are able to interact with them. [Azure docs - Authenticate access to Event Hubs resources using shared access signatures (SAS)](https://docs.microsoft.com/en-us/azure/event-hubs/authenticate-shared-access-signature)
  - The access security can be enhanced further by switching to using managed identities. [Authenticate with a managed identity to access Event Hubs Resources](https://docs.microsoft.com/en-us/azure/event-hubs/authenticate-managed-identity)
- Access to Azure portal, Application Insights, etc are restricted via native access polices built into Azure.

## Key Learnings

The following summarizes key learnings and best practices demonstrated by this sample solution:

### 1. Observability is a critical prerequisite, to achieving performance

- A system that cannot be measured, cannot be tuned for performance.
- A prerequisite for any system that prioritises performance, is a working observability system that can show key performance indicators.

### 2. Load testing needs representative ratios to test pipeline processing

- In streaming pipelines, the number of messages at each stage will vary. As messages are filtered and split, the messages going to each Event Hub output will be different to the ingestion Event Hub.
- In order to put each section under the expected production load, the load testing data needs to be crafted with representative ratios to exercise each section at the correct weight.
- If load testing data is not representative, an expensive section may be under tested. Which would falsely indicate that it would perform at production loads.
- It is important to do capacity planning on each stage of the pipeline. In this sample, it is expected that 50% of the devices will be filtered out in the first Azure Function (due not being the subset that we are interested in). It is expected that 20% of all temperature sensors will have values that need investigating and will go to the "bad temperature" Event Hub.

### 3. Validate test data early

- When initially testing, the crafted test data was not created at the correct ratios. It resulted in no filtering and everything being hit at 100% instead of smaller ratios deeper in the pipeline. This lead to an initial over-provisioning when testing and planning.
- Validating our test data earlier would have prevented this oversight.

### 4. Have a CI/CD pipeline

- This means including all artifacts needed to build the data pipeline from scratch in source control. This includes infrastructure-as-code artifacts, database objects (schema definitions, functions, stored procedures, etc), reference/application data, data pipeline definitions, and data validation and transformation logic.
- There should also be a safe, repeatable process to move changes through dev, test and finally production.

### 5. Secure and centralize configuration

- Maintain a central, secure location for sensitive configuration such as database connection strings that can be access by the appropriate services within the specific environment.
- Any example of this is securing secrets in KeyVault per environment, then having the relevant services query KeyVault for the configuration.

### 6. Make your streaming pipelines replayable and idempotent

- Messages could be processed more than once. This can be due to failures & retries, or multiple workers processing a message.
- Idempotency ensures side effects are mitigated when messages are replayed in your pipelines.

### 7. Ensure data transformation code is testable

- Abstracting away data transformation code from data access code is key to ensuring unit tests can be written against data transformation logic. An example of this is moving transformation code from notebooks into packages.
- While it is possible to run tests against notebooks, by shifting tests left you increase developer productivity by increasing the speed of the feedback cycle.

## Azure Function logic

The logic of the Azure Functions are kept simple to demonstrate the end to end pattern, and not complex logic within a Function.

### Device Filter

![Device ID filter](images/function-deviceidfilter.png?raw=true "Device ID filter")

All temperature sensors are sending their data to the `evh-ingest` Event Hub. Different pipelines can then consume and filter to the subset that they want to focus on. In this pipeline we are filtering out all DeviceIds above 1,000.

```javascript
// psuedoscript
if DeviceId < 1000
    forward to evh-filteredevices
else DeviceId >=1000
    ignore
```

### Temperature Filter

Splits the feed based on the temperature value. Any value of 100ºC and over are too hot and should be actioned.

![Temperature filter](images/function-temperaturefilter.png?raw=true "Temperature filter")

```javascript
// psuedoscript
if DeviceId < 100
    forward to evh-analytics
else DeviceId >=100 // it is too hot!
    forward to evh-outofboundstemperature
```

## EventHub & Azure Function scaling

- [Scaling Out Azure Functions With Event Hubs Effectively | by Masayuki Ota](https://medium.com/swlh/consideration-scaling-out-azure-functions-with-event-hubs-effectively-5445cc616b01)
- [Scaling Out Azure Functions With Event Hubs Effectively 2 | by Masayuki Ota](https://masayukiota.medium.com/scaling-out-azure-functions-with-event-hubs-effectively-2-55d143e2b793)

## Infrastructure as Code

We are provisioning Resource Group, Azure KeyVault, Azure Function, Application Insight Azure Event Hubs using Terraform.

### Modularize Terraform

In order to decouple each components of applications, we modularized each components instead of keeping all components in main.tf. We referred [official terraform site](https://www.terraform.io/docs/language/modules/develop/index.html) and artifact from CSE, [cobalt](https://github.com/microsoft/cobalt). By modularizing, we can run test as a unit. For example, to provision azure functions, we need to provision both storage account and azure functions.

### Isolation of Environment

We need different environment managed by terraform but often they have different scope of permission and possibly different resources you are provisioning. For example, you might have TSI in dev but not in staging environment. And thus we separated environment by file layout.

## Observability

Additional articles:

- [Observability on Event Hubs. Overview | by Akira Kakkar](https://akirakakar.medium.com/observability-on-event-hub-600c13d79b41)
- [Distributed Tracing Deep Dive for Eventhub Triggered Azure Function in App Insights | by Shervyna Ruan](https://medium.com/swlh/correlated-logs-deep-dive-for-eventhub-triggered-azure-function-in-app-insights-ac69c7c70285)
- [Calculating End-to-End Latency for Eventhub Triggered Azure functions with App Insights | by Shervyna Ruan](https://shervyna.medium.com/calculating-end-to-end-latency-for-eventhub-triggered-azure-functions-with-app-insights-e41023c3a292)

### Showing metrics on Azure dashboard

Utilizing the Azure dashboard can allow you to lay out the metrics of resources. Allowing you to quickly spot scaling and throughput issues.

![Portal dashboard](images/observability_portaldashboard.png?raw=true "Portal dashboard")

To create your own:

- On the Azure portal, go to the dashboard.
- Add 4 "Metrics", one for each Event Hub.
  - For each click `Edit in metrics`. Select the Event Hub name, then add `Incoming messages`, `Outgoing messages` and `Throttled requests`. Set the aggregate for each as `Sum`.
- Add 2 "Metrics", one for each Azure Function.
  - Add the metric, and select `Function Execution Count`
- Add `Application Map Application Insights` to see an end to end map of messages flowing through your infrastructure
- Add Markdown widgets, to add some explanations to others viewing the dashboard

![Event Hub metrics](images/observability_eventhubmetrics.png?raw=true "Event Hub metrics")

### Application Insights

Azure Event Hubs & Azure functions offer built-in integration with [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview). With Application insights, we were able to gain insights to further improve our system by using various features/metrics that are available without extra configuration. Such as Application Map, and End-to-End Transaction details.

#### Application Map

![Application map](images/application_map.png?raw=true "Application map")

Application Map shows how the components in a system are interacting with each other. In addition, it shows some useful information such as the average of each transaction duration, number of scaled instances and so on.
From Application Map, we were able to easily tell that our calls to the database are having some problems which became a bottleneck in our system. By clicking directly on the arrows, you can drill into some metrics and logs for those problematic transactions.

#### Azure Function Scaling

From Live Metrics, you can see how many instances has Azure Function scaled to in real time.

![Live metrics](images/function_instances_live_metrics.png?raw=true "Live metrics")

However, the number of function instances is not available from any default metrics at this point besides checking the number in real time. If you are interested in checking the number of scaled instances within a past period, you can query the logs in Log Analytics (within Application Insights) by using Kusto query. For example:

```kusto
traces
| where ......// your logic to filter the logs
| summarize dcount(cloud_RoleInstance) by bin(timestamp, 5m)
| render columnchart
```

![from logs](images/function_instances_from_logs.png?raw=true "from logs")

#### Distributed Tracing

Distributed Tracing is one of the key reasons that Application Insights is able to offer useful features such as application map. In our system, events flow through several Azure Functions that are connected by Event Hubs. Nevertheless, Application Insights is able to collect this correlation automatically. The correlation context are carried in the event payload and passed to downstream services. You can easily see this correlation being visualized in either Application Maps or End-to-End Transaction Details:

Here is an article that explains in detail how distributed tracing works for Eventhub-triggered Azure Functions: [Distributed Tracing Deep Dive for Event Hub Triggered Azure Function in Application Insights](https://medium.com/swlh/correlated-logs-deep-dive-for-eventhub-triggered-azure-function-in-app-insights-ac69c7c70285)

![Correlated logs](images/correlated_logs.png?raw=true "Correlated logs")

#### End-to-End Transaction Detail

End-to-End Transaction Detail comes with a visualization of each component's order and duration. You can also check the telemetries(traces, exceptions, etc) of each component from this view, which makes it easy to troubleshoot visually across components within the same transaction when an issue occurred.  

As soon as we drilled down into the problematic transactions, we realized that our outgoing calls(for each event) are waiting for one and another to finish before making the next call, which is not very efficient. As an improvement, we changed the logic to make outgoing calls in parallel which resulted in better performance. Thanks to the visualization, we were able to easily troubleshoot and gain insight on how to further improve our system.

![Transaction detail - sequential](images/e2e_transaction_detail_sequential.png?raw=true "Transaction detail - sequential")

![Transaction detail - parallel](images/e2e_transaction_detail_parallel.png?raw=true "Transaction detail - parallel")

## Load testing

The load testing script allows you to quickly generate load against your infrastructure. You can then use the observability aspects to drill in and see how the architecture responds. Azure functions scaling up, Event Hub queue lengths getting longer, and stabilising, etc. It will assist in finding bottlenecks in any business logic you have added to the Azure Functions, and if your Azure Architecture is scaling as expected.

Getting started resources:

- [Azure IoT Device Telemetry Simulator](https://github.com/Azure-Samples/Iot-Telemetry-Simulator/)
- [Azure Well Architected Framework - Performance testing](https://docs.microsoft.com/en-us/azure/architecture/framework/scalability/performance-test)
- [Load test for real time data processing | by Masayuki Ota](https://masayukiota.medium.com/load-test-for-real-time-data-processing-30a256a994ce)

### Load testing architecture

The load testing can be invoked by the [IoTSimulator.ps1](./loadtesting/IoTSimulator.ps1) script. This can be run locally via an authenticated Azure CLI session, or in an Azure DevOps pipeline using the load testing [azure-pipeline.yml](./loadtesting/loadtest-pipeline.yml) pipeline definition.

The script will orchestrate the test by automating these steps:

- Create or use an existing Resource Group
- Create an [Azure Container Instances](https://azure.microsoft.com/en-us/services/container-instances/) resource.
- Deploy the [Azure IoT Device Telemetry Simulator](https://github.com/Azure-Samples/Iot-Telemetry-Simulator/) container, and scale it to the number of instances passed in as a parameter.
- Coordinate them to simulate the specified number of devices, and send a certain number of messages.
- Wait for it to complete.
- Remove the Azure Container Instances resource.

Test message payload
Field name | Description
-- | --
deviceId | simulated deviceID
temperature | random temperature, in a ratio of good/bad readings
time | timestamp of value
