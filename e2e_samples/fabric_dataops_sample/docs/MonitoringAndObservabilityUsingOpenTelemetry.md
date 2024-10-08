# Observability in Data Projects Using OpenTelemetry 

-----------------
TO DO: Where do we keep the config file related to OTEL
- What is the preferred setup (VM + Docker ?) - we need to add this to the bgootstrapping
- Need to add the module from Mani to the environement
- Finalize env creation and making it defulat env 
- update workspcae creation step to add this as default env
- Open telemetry library - Need to add authentication and extensions - Check with Mani 

----------------------------------

## Introduction

Observability plays a crucial role in ensuring that a system or service is functioning as intended and **delivering value**. However, it is frequently neglected during the initial stages of a data project, leading to expensive rework and inadequate monitoring capabilities. Including observability from the very beginning is essential for assessing system performance, availability, planning future improvements based on resource utilization, and most importantly -monitoring the value delivered by the system. This article presents key considerations, best practices (such as naming conventions and common telemetry data schema), and techniques for combining business data with monitoring data.

Furthermore, this article delves into the implementation of monitoring and observability through the utilization of an open-source and vendor-agnostic framework known as [OpenTelemetry [OTEL]](https://opentelemetry.io/docs/what-is-opentelemetry/). There are various facets of monitoring, some of which are highlighted below, along with the corresponding services provided by Microsoft Azure:

- Application monitoring
  - Performance
  - Business metrics/Data quality
- Service monitoring
  - [Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/)
  - [Microsoft Fabric metrics](https://learn.microsoft.com/fabric/enterprise/metrics-app)
  - [Microsoft Fabric monitoring workspace](https://learn.microsoft.com/fabric/admin/monitoring-workspace)
  - [Microsoft Fabric monitoring hub](https://learn.microsoft.com/fabric/admin/monitoring-hub)
- Security monitoring
  - [User activity tracking](https://learn.microsoft.com/fabric/admin/track-user-activities)

This article focuses on application monitoring (user-generated telemetry).

## Monitoring and observability in data projects

Customers heavily rely on dashboards and metrics to evaluate the **business value** offered by a service or process. Therefore, it is crucial to capture all the necessary information at the appropriate granularity and frequency in order to generate these customer-facing dashboards. These dashboards can be operational-focused, functionality/business-focused, or a combination of both. The monitoring and observability (telemetry) data should enable reports on two main aspects of a data system/process:

- **Fit for for use**
  - Focus: Operational teams (SRE, INFRA/OPS etc.).
  - Purpose: Informs the users about the state of the system and its availbility for use including any anomalies, issues, or errors.
  - Examples: Access logs/metrics, performance metrics, system activities, uptime/downtime, response times, latency, processing times, volume, throughput, etc.

- **Fit for purpose**
  - Focus: Business teams (end users/customers).
  - Purpose: Informs the users whether system is delivering value by performing the tasks as specified in business requirements.
  - Examples: Data quality, service quality, end user interactions, service interruptions, customer satisfaction, etc.
  
Monitoring should encompass all the necessary information to generate metrics and dashboards specified by the operational and business teams to address these two aspects. This is typically achieved through a multi-step process, as outlined below, enabling teams to work efficiently in parallel:

1. Focus on the raw metrics/logs in the ETL code.
2. Implement processing steps on top of this raw telemetry data to generate alerts, aggregations, trends/patterns, analytics, and dashboards. Types of analytics that can be derived include:
   - *Descrptive and diagnostic analytics* to see what happened and why.
   - Leveraging AI/ML for *predcictive and prescriptive analytics* to make predictions and guide future actions/investments.

Here are some important considerations for observability:

- Establishing consistent [naming conventions](#sample-naming-conventions) and adopting [common schema/s](#sample-schema) for telemetry.
- Identifying Key Performance Indicators (KPIs) that are relevant to the business teams and customers.
- Understanding the operational requirements from SRE/INFRA/OPs teams.
- Defining alerts and monitoring requirements from both SRE/INFRA/OPs and business teams.
- Determining the type of monitoring needed, such as application, performance, user, infrastructure, or security monitoring. (Note: This article primarily focuses on application monitoring.)

In modern systems, telemetry data is crucial for reacting to failures, gaining insights into usage patterns, and proactively preparing the system for potential issues. For these reasons, it is important to treat observability data as a *data product* and apply the same level of rigor and standards to its development as with other core systems. For example, consider an infrastructure hosting service provider/vendor who charges customers based on their service usage. Here, proper tracking of resource usage becomes paramount as it directly impacts the revenue. Logs capturing usage patterns can also be valuable for generating additional revenue and facilitating cost optimization for both the vendor and the customer. The vendor can even market these logs as a product to the customer for deeper analysis by customer on their own, offering product recommendations and better usage planning.

## Using OpenTelemetry for monitoring and observability

In this section, we explore the implementation of  [OpenTelemetry [OTEL]](https://opentelemetry.io/docs/what-is-opentelemetry/) and its usage for capturing user-generated telemetry.

To understand the fundamentals of OpenTelemetry, you can refer to the [OpenTelemetry fundamentals](https://opentelemetry.io/docs/specs/otel/overview/#tracing-signal) documentation. Additionally, you can learn about OpenTelemetry signals and their significance in the [signals](https://opentelemetry.io/docs/concepts/signals/) section.

### Consider OpenTemetry setup options

There are mainly two ways of OpenTelemetry setup to make a system observable:

1. Using OpenTelemtry SDK directly ([No Collector](https://opentelemetry.io/docs/collector/deployment/no-collector/)).
   - [When to use](https://opentelemetry.io/docs/collector/deployment/no-collector/#tradeoffs)
   - Example: The script [otel monitor invoker.py](../src/fabric dataops python modules/src/otel monitor invoker.py) shows the use of OpenTelemetry SDKs directly by the application with Azure AppInsights as the target for monitoring data.
   - See [steps involved](#setup---using-opentelemetry-sdk-directly-no-collector-option).
2. Using OpenTelemetry [Collector](https://opentelemetry.io/docs/collector/)
   - [When to use](https://opentelemetry.io/docs/collector/#when-to-use-a-collector)
   - Example: [otel collector invoker.py](../src/fabric dataops python modules/src/otel collector invoker.py) shows the use of Collector which has multiple targets configured to serve as the targets for monitoring data.
   - See [steps involved](#setup---using-collector-option).

Option 1, whle easy to setup, it is not as scalable as the Collector based option (Option 2), which supports multiple targets as sinks for monitoring data using [exporters](https://opentelemetry.io/docs/concepts/components/#exporters).

Regardless of the chosen setup option, the process of generating traces, logs, and metrics remains the same. Refer to [nb-safety.ipynb](../src/notebooks/nb-safety.ipynb) to learn how this is achieved. Additional things to consider:

- Establish a [**common schema**](#sample-schema) for telemetry/obseverability data. This schema should define agreed-upon names and possible values for events, attributes, links, exceptions, etc. All developers should adhere to this schema when publishing traces, logs, and metrics. It should also include a section for custom attributes.
- Implement well defined [**naming convention**](#sample-naming-conventions) to facilitate easier correlation of events and artifacts, especially in cases where correlation IDs are not present. Using business-friendly terms or acronyms in artifact names or log messages, as opposed to system-generated IDs, significantly improves the user experience during log and event investigation.
- In situations where passing a *correlation ID* from one processes to another becomes impractical (see [context propagation](https://opentelemetry.io/docs/concepts/signals/traces/#context-propagation)), establish a convention to generate a unique, business-friendly ID that can be included in the telemetry. This ID can then be leveraged to combine, group, or relate events/spans/traces.

### Setup OpenTelemetry

The following sections describe setup needed for each OTEL setup option.

#### Setup - using OpenTelemetry SDK directly (no Collector) option

This doesn't require any setup other than using OpenTelemetry SDKs directly in the code as shown in the [OTEL library script](../src/fabric_dataops_python_modules/src/otel_monitor_invoker.py) and the [notebook](../src/notebooks/nb-safety.ipynb) where traces, logs and metrics are generated using this library.

#### Setup - using Collector option

This option shows [Code based solution](https://opentelemetry.io/docs/concepts/instrumentation/code-based/) using [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) as the means to gather telemetry data and export to supported target systems (like Azur emonitor, ADX etc.,). It involves the following components/steps:

1. One time setup - install the collector and configure it - typically done by infrastructure team/s:
  
      1.1. Installing the [Collecor](https://opentelemetry.io/docs/collector/installation/). Ensure the Collector is accepting requests from the clients (where telemetry is being generated).

      1.2. Creating the [Collector configuration file](https://opentelemetry.io/docs/collector/configuration/#basics). See the [sample file](#sample-otel-collector-configuration-file) below.

      1.3. Ensure Collector is up and running. See the sample commands to [kick-off Collector running on Docker](#sample-docker-based-collector-kickoff).

1. One time setup - perform target specific setup - typically done by Infrastructure team/development team:

    - Example: For [ADX and Kusto](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuredataexplorerexporter) you need to [create tables and enable streaming ingestion](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuredataexplorerexporter#database-and-table-definition-scripts).

1. One time developement activity - Create code packaged as a common library which creates OpenTelemtry providers for traces, metrics and logs using the Collector.
  
   - In this code sample, [otel_collector_invoker.py](../src/fabric_dataops_python_modules/src/otel_collector_invoker.py) is the common library for the Collector configuration.

1. Regular developement activity - Use common OTEL library, from above step, in the code to [capture observability data](https://opentelemetry.io/docs/languages/python/instrumentation/).

   - The [city safety notebook](../src/notebooks/nb-safety.ipynb) has code sample (may have been commented out) which uses [otel_collector_invoker.py](../src/fabric_dataops_python_modules/src/otel_collector_invoker.py).
   - Understand different ways to [create spans](#create-tracesspans). The [notebook](../src/notebooks/nb-safety.ipynb) also shows different ways of creating Spans.

### Create telemetry data

The following explains different types of OTEL spans and ways to create them and the [samples](#sample-files) contains examples of a [common schema](#sample-schema) and combining business data with telemetry data.

#### Understand OpenTelemetry span types

Spans are one type of [signals](https://opentelemetry.io/docs/concepts/signals/) generated by OpenTelemetry. There are primarily [two types of Spans](https://opentelemetry-python.readthedocs.io/stable/api/trace.html):

1. *Attached spans* which have *implicit context propagation*.

    Here new spans are *attached* to the context in that they are created as children of the currently active span, and the newly-created span can optionally become the new active span.

      Example:

      ```python
      # Create a new root span, set it as the current span in context
      with tracer.start as current span("parent"):
          # Attach a new child and update the current span
          with tracer.start as current span("child"):
              do work():
          # Close child span, set parent as current
      # Close parent span, set default span as current
      ```

2. *Detached spans* which needs to have *context set explicitly*.
  
    Here a span is *detached* from the context the active span doesn’t change, and the caller is responsible for managing the span’s lifetime.

      Example:

      ```python
      # Explicit parent span assignment is done via the Context
      from opentelemetry.trace import set span in context
      context = set span in context(parent)
      child = tracer.start span("child", context=context)
    
      try:
          do work(span=child)
      finally:
          child.end()
      ```

#### Create traces/spans

Typical flow looks like:

1. Create the *root span* as the very first step of the process/execution.
  
    1.1. Add *resource attributes* which are common for the entire process.

    1.2. Do your processing. Create child spans, events, logs and metrics as needed. Keep adding them to relavant spans.

1. Add the required attributes which are run/execution specific to the *root span* just before the end of the process/execution.

1. Close the *root span* and exit the process/execution.

See  [nb-safety.ipynb](../src/notebooks/nb-safety.ipynb) for implementation example.

Span creation can be done in multiple ways:

- By using the statements above (attached or detached span).
- By using [Python decorators](https://opentelemetry.io/docs/languages/python/instrumentation/#creating-spans-with-decorators).

Note:

- Any log message (using `logging.*`) in a *detached span* may not have traceId/SpanId information unlike an *attached span*.
- If you are creating spans using decorators then you should have `tracer` available before defining the functions so that it can be used as a *python decorator*. In our example - The notebook `nb-city-safety-common.ipynb` has a function `etl_steps` which uses this way to define span at function level.

## Sample files

### Sample naming conventions

See [sample naming convention](./ThingsToConsiderForDataProcesses.md#naming-conventions)

### Sample schema

#### Consider the list of attributes

The following shows a common list of attributes that should be considred for a common schema. All the names should be following a [naming convention](#sample-naming-conventions).

- Part of predefined schema (list may not be complete):
  - trace id
  - span id
  - span name
  - system timestamp (start and end)
  - span status
  - correlation id (if applicable)

- Required custom properties:
  - pipeline run id (pipe line run id If applicable)
  - business org
  - business domain
  - data product
  - workstream id
  - sub workstream id (if applicable - see the list of allowed values for Workstream names in Appendix)
  - environment (pick a value from pre-determined list)
  - tenant id
  - region (pick a value from pre-determined list)
  - pipeline name(follow good naming convention, number in the name helps with identifying execution sequence)
  - data period (if applicable)
  - data start date(if applicable )
  - data end date(if applicable)
  - inputs (if applicable)
    - [{type: “file”, location: “file/location.txt”}, …]
  - outputs (if applicable)
    - [{type: “table”, location: “mylakehouse.myschema.mytable”}, …]
      - exception(if applicable) (This may be part of the standard OTEL attribute - see semantic-conventions/docs/exceptions/exceptions-logs.md at main · open-telemetry/semantic-conventions (github.com))
  - {exception : {message : “custom message”, type:  “OSError”, stacktrace: “error stack trace”}}
  - process custom attributes (Custom properties specific to individual business process/teams)
    - {key: value, key2: value2}

#### Sample telemery schema

The following is a sample trace output using above elements as a reference for telemetry. This has 3 events - *data-extraction, data-transformation and data-load*. Note the usage of namespaces.

```yml
# This example (a sample trace output at ROOT level), shown using YAML format. 
TraceID: "<<trace id>>"
SpanID: "<<span id>>"
ParentID: "Null" # This is null as it is a root span
SpanName: "root#orgname#domainname#subdomain#appid123#env-dev#process-prefix#20240208211306" # used '#' instead of '.' to be consistent with usage in file names – this could be made shorter too – make it business friendly. This is the name of the span we used in the code.
SpanStatus: "STATUS.CODE_OK" # See OpenTelemetry Status codes
SpanKind: "SPAN_KIND.INTERNAL" # See OpenTelemetry Span kinds
StartTime: "2024-02-08T21:13:06.3641182Z"
EndTime: "2024-02-08T21:14:12.6966949Z"
ResourceAttributes:
  # Reserved attribute names
  deployment.environment: "prod"
  process.executable.name: "my-awesome-process-400" # process name
  service.instance.id: "In Fabric notebook, result of - mssparkutils.env.getJobId()"
  service.name: "x123" # business Organziation
  service.namespace: "d34" # domain
  service.version: "0.1"
  # custom attributes - business context
  service.project: "proj1"
  service.workstream.id: "ABC1234" # we can add sub-workstream ids as well as needed
  # custom attributes - execution context
  jobexec.region: "eastus"
  jobexec.environment: "dev"
  jobexec.tenant.id: "tenantid"
  jobexec.cluster.id: "In Fabric notebook, result of - mssparkutils.env.getClusterId()"
  jobexec.cluster.name: "In Fabric notebook, result of - mssparkutils.env.getPoolName()"
  jobexec.instance.name: "business friendly unique id - orgname#domainname#subdomain#appid123#env-dev#process-prefix#20240208211306"
  jobexec.workspacename: "In Fabric notebook, result of - mssparkutils.env.getWorkspaceName()"
  jobexec.context: "In Fabric notebook, result of -  string(mssparkutils.runtime.context)"
  jobexec.username: "In Fabric notebook, result of - mssparkutils.env.getUserName()"
  jobexec.userid: "In Fabric notebook, result of - mssparkutils.env.getUserId()"
TraceAttributes:
  # Reserved/default attributes
  scope.name: "__main__" # calling function
  # custom attributes - add them as needed
  etl.lakehouse.table name: "tbl city safety data"
  etl.src sql: "select * from city safety data"
  etl.custom attributes: { "key1": "value1", "key2": "value2" }
Events:
  # Add (custom) EventAttributes to each event as needed
  - EventName: "data-extraction"
    Timestamp: "2024-02-08T21:13:24.8623013Z"
    EventAttributes:
      inputs:
        - type: "file"
          location: "file/location.txt"
        - type: "table"
          location: "mylakehouse.myschema.myinputtable"
  - EventName: "data-transformation"
    Timestamp: "2024-02-08T21:13:27.4235698Z"
    EventAttributes:
      record count: 10202921
  - EventName: "data-load"
    Timestamp: "2024-02-08T21:13:27.4459314Z"
    EventAttributes:
      delta mode: "append"
      outputs:
        - type: "table"
          location: "mylakehouse.myschema.myoutputtable"
        - type: "file"
          location: "file/outputs YYYYMMDD/myfile.parquet"
Links: []
```

### Sample usecases for telemetry data

#### Combining reference data with telemetry data for alerting and additional metrics

Alerts based on thresholds and user notifications are often necessary. This can be achieved by using pre-defined configuration files or tables. The diagram below illustrates a straightforward approach to capturing execution metrics during application processing. These metrics are then combined with static/reference information about the process to generate alerts and dashboards as required.

![Log repostitory](../images/central_log_repository.png)

To effectively gather information such as response time, error rates, run times, etc., it is important to consider the following aspects:

- **What**: Define the specific metrics you want to capture, such as response time, error rates, run times, run time context etc. This will help in setting up the appropriate monitoring and alerting mechanisms.
- **How**: Capture the execution mechanism (pipelines, notebooks, sparkjobs, direct invokcation, called as a subprocess etc.).
- **Where**: Identify the environment or system where the application is running.
- **When**: Identify the time of events related to data (data periods/dates) and executions(system dates).
- **Who**: Determine the relevant identifiers for tracking the execution of the application. This could involve capturing execution IDs, user information, or any other relevant metadata that helps in correlating the metrics with specific executions or users.

#### Combine monitoring data with business data

Some common aspects that needs to monitored are:

- **Business metrics**: All applications in the end should contribute to generating value for the organization. So, it is extremely important to understand the Key Performance Indicators (KPIs) for the business team and incorporate logic to generate those logs/metrics for further analysis.
- **Performance metrics**: Performance monitoring involves measuring and analyzing the performance of the system by tracking metrics such as CPU usage, memory consumption, network latency, and response times. It may also include monitoring the application ability to meet the SLAs. Putting the system through large volumes of data (higher resource consumption, high concurrency processing etc.,) and gathering related execution metrics, combined with metrics from Infrastructure monitoring will indicate how the system is performing under load.
- **Data Quality metrics**: Data Quality Monitoring ensures that the data being used in the project is of high quality. It involves tracking metrics such as data completeness, accuracy, consistency, and timeliness and more. Data quality monitoring helps to identify data issues early on and allows for corrective action to be taken before it impacts the project outcomes.
- **Usage metrics**: It is important to gather metrics which enable customers to:
  - Identify and report resource use/Utilization details by each of their organisations/domains/customers.
  - For ISV like scenarios, have clear and controllable boundaries- distinguish between common portions and customer specific portions. For example in Microsoft Fabric the possible control boundaries are: domains, workspaces and compute capacity.
  - Present information with varied levels of granularity (At the service level and then service + customer level and so on.).

All these metrics can be combined with execution metrics as described in [the above section](#combining-reference-data-with-telemetry-data-for-alerting-and-additional-metrics) to correlate business events with operational events. For example, increased in number of invalid records due to a service outage, drop in customer ratings with increase in system response time, increased failure rate during quarter end for a financial organization etc.

### Sample OTEL Collector configuration file

Refer to [OTEL Collector configuration](https://opentelemetry.io/docs/collector/configuration/), [available exporters](https://opentelemetry.io/docs/languages/python/exporters/) and [End points and environment configuration](https://opentelemetry.io/docs/specs/otel/protocol/exporter/#configuration-options) for more details on available exporters and advanced configuration.

**Where data is sent**:

Given the sample configuration file contents below:

- For [ADX](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuredataexplorerexporter) data will be seen in `oteldb` (See [ADX DDLs](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuredataexplorerexporter#database-and-table-definition-scripts) ). Table names will be `OTELTraces` for Traces, `OTELLogs` for logs and `OTELMetrics` for metrics.
- For [App Insights/Azure monitor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuremonitorexporter)
  - Data will be seen in as follows:
    - Traces:
      - "dependency" for Spankind in [CLIENT, PRODUCER, INTERNAL]
      - "requests" for Spankind in [SERVER, CONSUMER]
    - Logs: "traces"
    - Metrics: "customMetrics"
    - Exception events: "exceptions"

The sample config below uses an Environement file(`env.cfg`) placed on the machine where Collector is setup.

```bash
# Azure App Insights
APPINSIGHTS CONNECTION STRING="<<App-insgights-connection-string>>"

# ADX and Kusto
AZURE TENANT ID="<<app-tenant-id>>"
RTI APP ID="<<app-id mentioned in `.add database oteldb ingestors ('aadapp=<clientid>')` in Kusto >>"
RTI APP KEY="<<secret key for RTI APP ID"
RTI CLUSTER URI="https://<fabric kusto cluster id>.kusto.fabric.microsoft.com"
ADX CLUSTER URI="https://<adx cluster name>.<adx cluster region name>.kusto.windows.net"
RTI DB NAME="oteldb"
```

Collector configuration file - This example assumes the targets are Azure Data Explorer (this supports both ADX clusters in Azure and Kusto databases in Microsoft Fabric) and Azure App insights.

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  debug:
    verbosity: detailed
  # AppInsights
  azuremonitor:
    connection string: ${env:APPINSIGHTS CONNECTION STRING}
  # ADX
  azuredataexplorer:
    cluster uri: ${env:ADX CLUSTER URI}
    application id: ${env:RTI APP ID}
    application key: ${env:RTI APP KEY}
    tenant id: ${env:AZURE TENANT ID}
    db name: ${env:RTI DB NAME}
    metrics table name: "OTELMetrics"
    logs table name: "OTELLogs"
    traces table name: "OTELTraces"
    ingestion type : "managed"
  # Kusto
  azuredataexplorer/2:
    cluster uri: ${env:RTI CLUSTER URI}
    application id: ${env:RTI APP ID}
    application key: ${env:RTI APP KEY}
    tenant id: ${env:AZURE TENANT ID}
    db name: ${env:RTI DB NAME}
    metrics table name: "OTELMetrics"
    logs table name: "OTELLogs"
    traces table name: "OTELTraces"
    ingestion type : "queued"
    # ingestion type : "managed"

processors:
  batch:

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuredataexplorer/2]
    traces/2:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuredataexplorer, azuremonitor]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuredataexplorer, azuremonitor]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuredataexplorer, azuremonitor]
```

### Sample Docker based Collector kickoff

Assumptions:

- The Collector is running and where the server/machine where it installed is allowing traffic (check the ports for the Protocol used HTTP vs GRPC etc.,) from the clients which are sending telemetry data (either through authentication tokens which are part of api calls or by allowing the IPs/Services using network access controls/security group settings).
- The Collector configuration file is named `otel-collector-config.yaml` and optionally environment globals are in `env.cfg`.

Given the above assumptions, for a *Docker based installation* the Collector service can be started using something like :

```bash
docker run -p 4317:4317 -p 4318:4318 --rm -v <collector-configfile.yaml>:<docker volume> <docker image to use>
```

Example:

```bash
docker run -p 4317:4317 -p 4318:4318 --rm -v "<path-to-config-file>\otel-collector-config.yaml:/etc/otelcol-contrib/config.yaml" otel/opentelemetry-collector-contrib:latest
```

with name for the container and using an environment file (env.cfg):

```bash
docker run --name otel-collector -p 4317:4317 -p 4318:4318 --env-file <path-to-env-file>/env.cfg -v <path-to-config-file>/otel-collector-config.yaml:/etc/otelcol-contrib/config.yaml otel/opentelemetry-collector-contrib:latest
```

## For more information

- [Azure monitoring best practices](https://learn.microsoft.com/azure/architecture/best-practices/monitoring)
- [Azure monitor and OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-overview)
- [OpenTelemetry Logs Data model](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/logs/data-model.md)
- [OpenTelemetry Cookbook](https://opentelemetry.io/docs/languages/python/cookbook/)
- [MS Learn Playbook: Data observability](https://learn.microsoft.com/data-engineering/playbook/capabilities/data-observability/)
