# Things to consider while building data processes

## General
  - Know he dataflow - understand high level flow - this is important to know the tech stak, possible interfaces, environemtn etc.,
  -     - understand exiting tools and compatability, scability and security, encruption, data privacy, treatment of NPI data
  - if there is notebook in piepline - just use it directly
  - try to absolute paths as much as possible - when using %run - defult valakehouse is set based on the calling notebook (not the iner ones).

## Document the assumptions and known limitations

## Know the KPIs

 design moinotring around it.
 know what success means.
 - combine with monitoring
 - four types of anlaytics - atleast first two should be implemented without faile; second two - plan for provisions - as things evolve

## Secure the application/setup

  - Use of VPNs and endpoints
  - Setup key vaults
  - Agree on secrets rotation policy
  - SPNs, managed ids, worksspaceids, RBAcs, 
  - Protecting data at rest and in flight
  - user access monitoring/privs
  - Know the limitations of Fabric

## Naming conventions

Adopt a naming convention. This should cover all aspects of the data estate. A few of them are:

- Telemetry (monitoring and observability schemas).
- Metadata schemas for data reconcilations.
- Events and alerts from one system to another.
- Databases and lakehouses covering all artefacts at all levels (folders, files, database objects like schemas, functions, triggers, procedures etc.).
- Reporting artefacts.

### sample naming convention

Dates/Timestamps:

- Follow a preferred format (ISO8601). If used in names, use `YYYYmmDDTHHMMSSZ` as it avoids any other special characters in the value and is based on ISO8601 format.
- Follow a time zone (Example: UTC).
- Agree on the granularity (microseconds or nanosecondas etc.).
- Understand that there are different types of dates. For example:
  - Data (activity) period/date - Period to which data belongs to.
  - Execution (start or end) date - dates related to the execution of the process.
  - Effective (start or end) date - dates on which something goes effective.

Resource naming:

- Understand the limitations/constraints of the technology/tool being used (Examples: length limitation, usage of special characters etc.).
- Avoid usage of delimiters which could cause issues based on the OS (Examples: `;`, `/`, `:`, space etc.).
- Maintain a consistent case (lower or camel etc.).
- Use a naming conevntions for resources. Here are a few references:
  - [Azure resources abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
  - OpenTelemtry recommendations(names and namespaces):
    - [Attribute Naming](https://opentelemetry.io/docs/specs/semconv/general/attribute-naming/)
    - [Semantic conventions](https://opentelemetry.io/docs/concepts/semantic-conventions/)
- Use abbreviations for frequently used ones as much possible. Examples include: domains, organizations, Azure resources, workstream names, application names etc.
- Use descriptive names for databases, tables and schemas.
- For files use a combination of common business prefixes, when the file was generated and by which process, data periods etc. See the example below.
- Keep common portions as prefix. This will make sorting and searching easier.
- Use a sequence number to convey a flow/execution sequence. Account for growth and space them appropriately. For example, instead of using 1, 2, 3 try a series like – 100, 200, 300. In future if there is a new process between 100 and 200 – you can use something like 110 and so on.

Examples:

- common prefix to indicate a group of processes: `common prefix` = `<org prefix>#<domain>#<subdomain>#<business-prefix>`
- use this common prefix for naming processes, inputs and outputs:
  - `process name` = `<common prefix>#<sequencenumber>#<process name>`
  - `runid` = `<process name>#<runtime expressed as YYYYmmDDTHHMMSSZ>`
  - `file name` = `<runid>#<optional:descriptive name><optional:data activity period>.<filetype>`

## Common schemas

- For telemetry consider a common schema which uses attributes as per naming conventions. See [sample common schema](./MonitoringAndObservabilityUsingOpenTelemetry.md#sample-schema) for details.
- Similarly, adopt common schemas covering the entire data estate. A few examples:
  - Alerts and monitoring.
  - Data reconciliation.
  - Data exchange.
  - Triggering events etc.


## Consider the security 

- Data security
  - key vaults
  - SPs, managedids, workspace ids
  - security for : Data inflight and data at rest 
  - 
- Application security
  - vnet setup
  - Network rules
  - Private endpoints
  - vm setup
```
  <!-- # # Add this to Security groups - if we are using VM for otel collector
# #   OR include authentication token in each request message (based on the implementation menthod)
# import requests
# print(requests.get('https://api.ipify.org').text) -->

```

## Organize code

- Notebook Vs coding
  - best practices and guidance (notebooks vs whl - why and how to choose - testability is one aspect and colloboration; use notebook early or colloboration or orchetrator and put most code in external libs - mo9dulese)
    - if its script we can make it part of env etc. If its notebook then the notebook has to be part of a workspace or need to be part of the resources.
  - for .py converted from notebooks - magis are stored as - `get_ipython().run_line_magic('run', 'test_notebook')`. the best way would be `ipython <converted-python-script>.py`. Note: Importing it via from IPython import get_ipython in ordinary shell python will not work as you really need ipython running.

### Formatting the Notebook

Use `jupyter_black` to format the code. See [Formatting Microsft Fabric notebook](https://learn.microsoft.com/fabric/data-engineering/author-notebook-format-code#extend-fabric-notebooks) for details.

    ```python
    #  %load_ext jupyter_black OR
    import jupyter_black
    jupyter_black.load()
    ```
**WARNING**: This formatting might delete the *cell magic** commands if present. Ensure they are added back after formatting.

  - Organzie notebook
    - Formatting: - https://learn.microsoft.com/en-us/fabric/data-engineering/author-notebook-format-code#extend-fabric-notebooks
    - use organize everything fucntions as much as possible so that we can leverage %run command and use the fucntions from notebook in another notebook like a module. 
    - 
### common libraries

- common code availability
  - biultin at notebook level 
     - dis: need to copy the resources each time, might be suitable for things which are not running frequently
     - adv: light weight, latest versions can be picked without migration to the existing code. We don't have to worry about workspace boundaries as code can be copied from a central/commmon workspace.
  - builtin at env level (no apis yet)
     - same above; right now no api support for this
  - env modules
     - adv: no need to copy during each run
     - need to redeploy the code(env) with new changes for the env. Might be difficult as envs can't be shared across envs.
  
Here is a sample code snippet to upload Python libraries from Public repor:

    ```python
    # Adding Python modules from public repo
    import requests  
    
    # Replace the placeholders with your actual values  
    workspace_id = "{{WORKSPACE_ID}}"  
    artifact_id = "{{ARTIFACT_ID}}"  
    url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/environments/{artifact_id}/staging/libraries"  
    token = notebookutils.credentials.getToken('pbi')
    
    # Create the payload  
    payload = {}  
    files = {  
        'file': ('environment.yml', open('environment.yml', 'rb'), 'multipart/form-data')  
    }  
    
    # Set the headers  
    headers = {  
        'Authorization': f'Bearer {token}'  
    }  
    
    # Send the POST request  
    response = requests.post(url, data=payload, files=files, headers=headers)  
    
    # Check the response  
    if response.status_code == 200:  
        print("File uploaded successfully.")  
    else:  
        print("File upload failed.")  
        print(response.text)  
    
    # Next Steps:
    #  1. Publish the env
    #  2. Associate the env with a workspace
    ```
where contents of environment.yml will look something like:

```yaml
dependencies:
  - pip:
      - jupyter-black==0.3.4
      - black==24.4.2
      - pytest==8.2.2
      - ipytest==0.14.2
      - opentelemetry-exporter-otlp==1.25.0
      - azure-monitor-query==1.4.0
      - azure-monitor-opentelemetry-exporter==1.0.0b28
      - opentelemetry-exporter-otlp==1.25.0
```

### Understand making calls to other notebooks/code modules

- Makes the functions available to local session. Only functions definitions any other common params needed are defined in this library notebook. Shown here with an optional parameter that can be used to skip some portion of the code inside a cell.
- These functions incorporate Opentelemetry based traces and logs generation using the OpenTelemetry providers created in the previous step. See the code in nb_city_safety_common.ipynb for details.
- Note that the entire notebook will be run.
- **WARNING**: If there are any variables with the same name then the notebook values that is being called will replace the values in the current notebook context. In the example below - `%run nb_city_safety_common {"execution_mode": "testing"}` will result in `execution_mode = "testing" ` in current context as well.

## Make the code configuration driven

Use config files/parameter options and always avoid hardcoding of the values/names etc. Ensure application can run any environment, just by updating the user agruments or using proper values for the given environment/stage in the configuration/parameter file, without requiring any code changes.

### Using parameters in Fabric notebooks
There are multiple ways parameters can be set when using Microsft Fabric notebooks.

There are multiple options to set the paramerts. First two options leverage the system config update (reserved keyword) for default lakehouse. Advantage here is all relative paths are honored.
1. using `%% configure` option - this needs to be the first cell  OR the session needs to be restarted. See - https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#spark-session-configuration-magic-command
    - Only some cofig params like default lakehouse, besides spark session config params are honored. For the rest we need to rely on parameters cell(option 3)
2. Sending parameters as part of execution invoke using API - we can use "config" boody to send the params. See - https://learn.microsoft.com/fabric/data-engineering/notebook-public-api#run-a-notebook-on-demand
    - Similar to option 1, Only some config params like default lakehouse, besides spark session config params are honored.
3. Using parameters cell and Using absolute paths then deriving all other paths based on that. This cell can anywhere (just understand the run time behvior if it).
    - Option 3 can be used for anything. Here, the disadvatage is relative path(with reference to default lakehouse) can't be used here , as there is no default set.


### Plan for overrides
-  Good option to use something like https://docs.python.org/3/library/configparser.html
-  Set default values to avoid errors (there could be some things like Tracer which must always be defined - consider those if statemetns where not taking one path could cause failure)


### Static/REference data

- where to keep it
- how to source it (could be a config file using config parser or we can make it like a library and import it like a module)

- Think something like Process data - exteremely useful for monitoring processes:

A sample reference data for a process could be like this:

```yaml
# Read the file contents from the process name passed as the input parameter (process_configs/<domain>#<app_id>#<sub_app_id>#<process_name>.yaml)
# this needs to be moved else where
# assume one yaml per process and a process folder will have all these process level config files
# Example contents:
process_name: "SampleProcess"  
description: "This is a sample process"  
process_status: "Running"  
upstream_processes:  
  - "ProcessA"  
  - "ProcessB"  
downstream_processes:  
  - "ProcessC"  
  - "ProcessD"  
priority: "high"   
scheduling_info:  
  start_time: "09:00"  
  end_time: "18:00"  
  frequency: "Daily"  
slas:  
  response_time: "2 hours"  
  availability: "99.9%"  
monitoring_info:  
  enabled: true  
  frequency: "Every 5 minutes"  
  metrics:  
    - "CPU"  
    - "Memory"  
    - "Disk"  
alerting_info:  
  enabled: true  
  thresholds:  
    cpu_usage: 90  
    memory_usage: 80  
process_owner_info:  
  name: "John Doe"  
  email: "johndoe@example.com"  
effective_start_date: "2022-01-01"  
effective_end_date: "2022-12-31"  
custom_notes: "This process requires additional approval"  

```

## Implement monitoring and observability

- should be included from the beginig
- in this example - opentelemetry used for gathering business and resources data.
  - Business data: See OTEL instrumentation
  - TO DO: Azure resources: see how to enable to monitoring in each of the resources for sending data to OTEL

TO DO: - Other data from Azure and Fabric -  like secutity and user acvitvity
- https://learn.microsoft.com/en-us/fabric/admin/track-user-activities
- https://learn.microsoft.com/en-us/fabric/enterprise/metrics-app
- https://learn.microsoft.com/en-us/fabric/admin/monitoring-workspace
- https://learn.microsoft.com/en-us/fabric/admin/monitoring-hub

 As of now gathering data from monotring hub using APIS is an issue. We can use APIs to gather above user related info for PowerBI/Fabric using some scheduled activity and eventually once mointoring hub apis are available - combine with that info as well.

- Explain different ways of setup (authentication of telemetry data at message level or allowlisting the Fabric ips. As of now there is no service tag that is allowed for Fabric resources).
   - explain advatages and disadvantages with each approach.
- Also mention about naming conventions

See [OpenTemetry.md](./OpenTelemetry.md) on how to use OpenTelemetry.

## Plan for testing from day one.

    - write functions
    - write unit tests
    - know the teting priorities.
    - be proactive.

    - Testing - See unit section later in the doc
  - configuration of all stage related settings(connections etc)
  - unit vs system vs integration
  - shakeout tests
  - take a complex piepline and explain what is unit and what is system etc
  - 
## Value proposition

    - fit for purpose -- DQ
      - DQ: Two types:
        - Measures - great expectations
        - PArt of data and inflight - decisions for later - custom ETL/Rule engine
    - fir for use -- monitoring

## Combining Operations with Business data
  
## Visualizations
  
## Maintenance tools

  - Utilities for - See Maintenance section in the end:
  - Names
  - Daily and scheduled maintenance (Space, cost optimization, aggregate bahvior monitoring etc)