# Key Considerations for Building Data Processes

***This list is not exhaustive and is a work in progress.***

This document offers insights into the crucial factors to consider when working on data projects, specifically focusing on the utilization of [Microsoft Fabric](https://learn.microsoft.com/fabric/). While the steps outlined here are not exhaustive and may not delve into the finer aspects of end-to-end design, you can find a comprehensive solution that covers all the necessary details for end-to-end design in the [Exploring Modern Data Warehouse (MDW)](https://learn.microsoft.com/data-engineering/playbook/solutions/modern-data-warehouse/) solution documented in [Data Playbook](https://learn.microsoft.com/data-engineering/playbook/?branch=main).

## General

- [Follow good coding practices](https://microsoft.github.io/code-with-engineering-playbook/).
- Understand and document high level flow. Be part of architecture design sessions. This is important to know the tech stack, possible interfaces, stakeholders,environment etc.
- Understand the problem statement.
- Understand exiting tools and compatability, scability and security, encryption, data privacy, treatment of NPI data etc.

Notebooks:

- If there is only a notebook in the Fabric data pipeline, you can schedule/run it directly with out needing a pipeline.
- Use absolute paths (as opposed to relative paths) as much as possible. Note that when using `%run` - default lakehouse is set based on the calling notebook (not the ones which are being run).
- `%run` behavior is different than `notebookutils.notebook.run`.

## Document the assumptions and known limitations

- Document assumptions covering entire data estate (Tools, techonologies, data flow, business logic etc.).
- Document any known limitations.
- Document known errors and work arounds.

## Know the KPIs

- Understand what is the success criteria and how to measure it. Define [Key Performance Indicators (KPIs)](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-kpi?tabs=powerbi-desktop#when-to-use-a-kpi).
- Design the application/process with [observability](#implement-monitoring-and-observability) in mind.
- Understand the [types of anlaytics in modern data systems](https://learn.microsoft.com/data-engineering/playbook/solutions/modern-data-warehouse/?branch=main#learn-about-the-traditional-data-warehouse-vs-the-modern-data-warehouse) - Descriptive, diagnostic, predictive and presriptive analytics. Know what are the right metrics under each category for the project/service. While descriptive and diagnostic analytics can typically be incorporated during the planning stages, predictive and prescriptive analytics may require some experimentation to determine the most valuable metrics.

## Naming conventions

Adopt a naming convention. This should cover all aspects of the data estate. *A few* of them are:

- Telemetry (monitoring and observability schemas).
- Metadata schemas for data reconcilations.
- Events and alerts from one system to another.
- Databases and lakehouses covering all artefacts at all levels (folders, files, database objects like schemas, functions, triggers, procedures etc.).
- Reporting artefacts.

### Sample naming convention

#### Using dates and timestamps

- Follow a preferred format (ISO8601). If used in names, use `YYYYmmDDTHHMMSSZ` as it avoids any other special characters in the value and is based on ISO8601 format.
- Follow a time zone (Example: UTC).
- Agree on the granularity (microseconds or nanosecondas etc.).
- Understand that there are different types of dates. For example:
  - Data (activity) period/date - Period to which data belongs to.
  - Execution (start or end) date - dates related to the execution of the process.
  - Effective (start or end) date - dates on which something goes effective.

#### Naming resources

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

#### Examples

- Common prefix to indicate a group of processes: `common prefix` = `<org prefix>#<domain>#<subdomain>#<business-prefix>`
- Use this common prefix for naming processes, inputs and outputs:
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

## Secure the application/setup

- Use of VPNs and endpoints
- Setup key vaults
- Agree on secrets rotation policy
- SPNs, managed ids, worksspaceids, RBAcs
- Protecting data at rest and in flight
- user access monitoring/privs
- Know the limitations of Fabric
- Data security
  - key vaults
  - SPs, managedids, workspace ids
  - security for : Data inflight and data at rest

- Application security
  - vnet setup
  - Network rules
  - Private endpoints
  - vm setup

```python

  <!-- # # Add this to Security groups - if we are using VM for otel collector
# #   OR include authentication token in each request message (based on the implementation menthod)
import requests
print(requests.get('https://api.ipify.org').text)

```

## Organize code

- Use fucntions/classes  as much as possible and other best coding pracitces to organize the code and enable unit testing. For notebooks, you can leverage `%run` command and use the fucntions from notebook in another notebook like a module.

- Notebook Vs Python packages
  
  - Notebooks are great for colloboration, have the Spark environment readily available and support multiple progragmming languages(PySpark, Shell, PySparkSQL etc.) in the same notebook. These are great for colloborative development, sharing ideas and can serve as an orchestrator all by themseleves. However, these are not easy to test and will almost certainly need an other notebook to call these.
  - Python packages are suitable for their testability, reusability and the ability to enforce coding standards. However, these are not as flexible as notebooks and might slowdown development a bit, especially in the initial stages.
  - One option is to start with notebooks in the early stages of development and as code becomes a little stable, these can be converted in to Python modules/packages for greater reuse.
  - For `.py` files which are converted versions of `.ipynb` magic methods are stored as `get_ipython().run_line_magic('<your magic name>', '<magic method input arguments>')`.

### Formatting the Notebook

Use `jupyter_black` to format the code. See [Formatting Microsft Fabric notebook](https://learn.microsoft.com/fabric/data-engineering/author-notebook-format-code#extend-fabric-notebooks) for details.

  ```python
  #  %load_ext jupyter_black OR
  import jupyter_black
  jupyter_black.load()
  ```

**WARNING**: This formatting might delete the *cell magic** commands if present. Ensure they are added back after formatting.

### Common resources

Known limitation:

- As of Aug 2024, Fabric deployment pipeline doesn't copy Fabric resources. This is true for both environment and notebook resources.

Known issues:

- As of Aug 2024, Fabric notebooks when deployed using Fabric deployment pipeline, still carry references to old environment (from the source/upstream workspace in the deployment pipeline). This most likely the item definition has environment id as part of it. The workaround is to update it using portal or using update item api for notebook.

Fabric resources provide a file system that enables you to manage your files and folders. Some artefacts which are good candidates for hosting resources are:

- Configuration files.
- Reference/static data.
- Common utility scripts which are not part of the common libraries.
  - Think of a hieararchy where there is a common "domain level" environment that is shared by all, and there a small number of overrides/custom objects for individual teams. In this case instead of maintaing one Fabric environment for each team - teams can levereage resources for customization.

Note: Fabric resources can be either environment level or notebook level resources. The difference between these resources and OneLake is that - the file system can be treated as a local file system using `notebookutils.nbResPath`. For any code, that can't read from `abfss` paths these resources are useful comapred to OneLake path. In all these cases, deployment scripts can be utilized to create/copy files for one time steup.

 The below sections explain how to create Fabric resources.

#### Environment resources

Manual management:

- Fabric frontend can be used to maintain [Fabric envinrment resources](https://learn.microsoft.com/fabric/data-engineering/environment-manage-resources).

Programmatic management:

As of Aug 2024, there is no API support to upload resources. The below workaround can be adopted for programmatic uploads using ADLS2 as a source.

- Create a notebook and associate that notebook with the Fabric environment where you want to add resources.
- Add the following code to the notebook:

    ```python
    # This will copy from ADLS to Fabric environment resource area- no need to perform any additional deployments/publish. The file is availble to all artefacts which are using this Fabric environment.
    notebookutils.fs.cp("abfss://<container-name>@<storage-account-name>.dfs.core.windows.net/<relative-path>/<file-name>", f"file:{notebookutils.nbResPath}/env/<file-name>")
    ```

- Run the notebook.

#### Notebook resources

Manual management:

- Fabirc frontend can be used to maintain [Fabric notebook resources](https://learn.microsoft.com/fabric/data-engineering/how-to-use-notebook#notebook-resources).

Programmatic management:

As of Aug 2024, there is no API support to upload resources. The below workaround can be adopted for programmatic uploads using ADLS2 as a source.

- Open the notebook where you want to add resources.
- Add the following code to the notebook:

    ```python
    # This will copy from ADLS to Fabric notebook resource area - The file is available to all sunsequent sessions of the runbook.
    notebookutils.fs.cp("abfss://<container-name>@<storage-account-name>.dfs.core.windows.net/<relative-path>/<file-name>", f"file:{notebookutils.nbResPath}/builtin/<file-name>")
    ```

- Run the notebook.

### Static/reference data

This is the information that is often source controlled (maintained as part of the code repositories),rarely changing, and may or may not be loaded into tables. Some examples include:

- Zip codes/postal codes
- Geographic regions
- Date dimensions
- Business lookup data for codes, flags, indicators etc.

This information can be hosted using [Fabric resources](#common-resources) either at environment level or notebook level. **The key distinction between this and OneLake file system files is that the customers prefer to have these source controlled.**
  
#### Sample reference data for a process

Consider information about a process/system like stake holders, SLA requirements, mail distro etc. This information can be combined with telemetry data to generate alerts, identifying right people etc. A sample reference data for a process could be as follows:

  ```yaml
  # Read the file contents from the process name passed as the input parameter (process_configs/<domain>#<app_id>#<sub_app_id>#<process_name>.yaml)
  # assume one yaml per process and a process folder will have all these process level config files
  # Example contents:
  process_name: "SampleProcess"  
  description: "This is a sample process"  
  process_status: "active"  
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
  custom_notes: "This is my custom comment"  
  ```

### Common libraries

In Fabric, common code be made availble in multiple ways using:

- [Fabric environment custom libraries](#managing-custom-libraries-using-fabric-environments): This applies for python libraries only. Can be source controlled with Fabric environment. Another advanatge is a deployment pipeline can copy these artefacts into next stage. Disadvantage is if there is a change then environment also need to be re-built and deployed which is a slow process. This could also cause issues for issues for other users who are sharing the environment.
- [Fabric resources](#common-resources): These can be notebook built in resources or environment level resources. The addition of artefacts can be done using notebooks/code which woudln't require redeployment of environment in the case of environement resource update. While this is faster, it has the potential of allowing authorized changes. Note that, deployment pipelines currently (as of Aug 2024) don't support copying these resources into next stage.

#### Managing public libraries using Fabric environments

See [Fabric public libaries](https://learn.microsoft.com/fabric/data-engineering/environment-manage-library#public-libraries) for details.

Assume that you need a few public libraries included in your project. Then, create a file with the name `environment.yml` and the contents will be names and versions of the libraries you need:

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

Here is sample code to upload these public libraries using `environment.yaml`. See [Fabric environment APIs](https://learn.microsoft.com/fabric/data-engineering/environment-public-api) for details.

  ```python
  # Adding Python modules from public repo
  import requests  
  
  env_file = 'environment.yml'  # File name MUST be "environment.yml"
  
  # Replace the placeholders with your actual values  
  workspace_id = "{{WORKSPACE_ID}}"  
  artifact_id = "{{ARTIFACT_ID}}"  
  url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/environments/{artifact_id}/staging/libraries"  
  

  token = notebookutils.credentials.getToken('pbi') # this will work if working from a notebook. If not get token using alternate methods.
  
  # Create the payload  -
  payload = {}  
  files = {  
      'file': (env_file, open('<path_to_environment.yml>/env_file', 'rb'), 'multipart/form-data')  
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
  ```
  
Next steps:

- [Publish the environment](https://learn.microsoft.com/fabric/data-engineering/environment-public-api#make-the-changes-effective).

#### Managing custom libraries using Fabric environments

See [Fabirc custom libraries](https://learn.microsoft.com/fabric/data-engineering/environment-manage-library#custom-libraries) for details.

- Create the Python module (could be a `.py` or `.whl` or `.tar.gz`).
- Follow the same sample code used [above](#managing-public-libraries-using-fabric-environments) after replacing `env_file` with the name of the module you created.

### Understand making calls to other notebooks/code modules

- `%run` can be used to run a notebook and make its functions available to the local notebook.

- `%run` only recognizes notebooks from same workspace or from notebook *builtin resources* area (using `%run -b`). `notebookutils.notebook.run` can run notebooks from other workspaces but the functions in the called notebook won't be visible to current notebook (no module like treatment). So the notebook examples here uses `%run` to run the notebooks with library functions and make those functions visible to the calling notebook (or testing notebook).
- As of Aug 2024, `%run` doesn't support variable replacement option i.e., no parameters can be passed as arguments to the run command. See [run a notebook](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#reference-run-a-notebook) for details.
- **WARNING**: If there are any variables with the same name then the notebook values that is being called will replace the values in the current notebook context.

In the example: `%run nb_city_safety_common {"execution_mode": "testing"}` will result in `execution_mode = "testing"` in current context as well.

## Make the code configuration driven

To improve the flexibility and avoid hardcoding values, you can utilize configuration files or parameters options. This approach allows you to update the necessary values or control the run time behavior without modifying the code itself.

The notebook [nb-city-safety.ipynb](../src/notebooks/nb-city-safety.ipynb) has examples of the topics discussed below.

### Using parameters in Fabric notebooks

There are multiple ways parameters can be set when using Fabric notebooks:

1. [Using Spark session configuration](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#spark-session-configuration-magic-command)- You can use  `%% configure` to configure spark session. This needs to be the first cell  OR the session needs to be restarted.
1. Sending parameters as part of the execution:
   - [Invoke using API](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api#run-a-notebook-on-demand) - You can use "configuration" boody to send the params.
   - [Designate a parameters cell](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#designate-a-parameters-cell) and [read parameters from a pipeline](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#parameterized-session-configuration-from-a-pipeline).

Note that [Parameters cell](https://learn.microsoft.com/fabric/data-engineering/author-execute-notebook#designate-a-parameters-cell) will work regardless of the method chosen.

To ensure proper functionality, it is recommended to set the `defaultLakehouse` when working with relative paths in your notebook. By doing so you can avoid any potential issues that may arise from using relative paths.  If the defaultLakehouse is not explicitly defined, the notebook will automatically adopt the lakehouse it was initially associated with during creation as its default lakehouse. **Best practice is to avoid relative paths while coding and use absolute paths**. This practice will also help avoid any conflicts when executing notebooks using `%run`, as the default lakehouse of the main notebook will serve as the default lakehouse for the session during reference runs.

### Plan for overrides

Processes should allow for overriding paramaeters/input arguments for scenarios like testing or to customize for a particular environment.

- Good option to use something like Python's [configparser](https://docs.python.org/3/library/configparser.html).
- Set default values to avoid errors (there could be some things like Tracer which must always be defined - consider those if statemetns where not taking one path could cause failure)

### Using configuration/parameter files in Fabric

This section describes a few ways to stage configuration files for use in Fabric.

#### Config values stored as a valid python file/module

There are multiple ways to include the configuration file stored as a Python module/file. The options to manage the config file and the way to use are:

- [Custom library](#managing-custom-libraries-using-fabric-environments).

    ```python
    # if added to environment as a library
    import <your_config_name> as myconfig
    
    # Another option to access the file directly if added to enviroment as a custom library
    import site
    your_moudle_file = site.getsitepackages()[0]/<your_config_name>.py
    
    # use your_module_file as needed - including using `configparser` to read this file.
    ```

- [Environment resource](#environment-resources)

    `import env.<your config name> as myconfig`

- [Notebook resource](#notebook-resources)

    `import builtin.<your config name> as myconfig`

#### Custom config file formats (file is not a valid python module/file)

There are a few ways to include the configuration file which is not a valid python module/file. This can done using the config file as a:

- [Environment resource](#environment-resources).
  - Resource can be accessed as `f"{mssparkutils.nbResPath}/env/<your_config_file>"`
- [Notebook resource](#notebook-resources).
  - Resource can be accessed as `f"{mssparkutils.nbResPath}/builtin/<your_config_file>"`

In both cases, the file can be accessed using python file operations. Here is a code sample which uses Python's `configparser` to read the config file which is in `.ini` format.

  ```python
  # config parser has rich features to read config files written in .ini format including support for interpolation
  import configparser
  config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())

  # Reading file stored as environment resource
  config.read(f"{mssparkutils.nbResPath}/env/<your_config_file>")

  # Reading file stored as environment resource
  config.read(f"{mssparkutils.nbResPath}/env/<your_config_file>")        
  ```

Note:

- `configparser` can only read from local file structure (but not ADLS paths). So, in this case we need a way to copy config file to (environment or notebook) resource path.
- Files can also be copied to OneLake using APIs.

## Implement monitoring and observability

Similar to testing, observability should be part of a system design from the begining. See [observability section](./MonitoringAndObservabilityUsingOpenTelemetry.md) on how to implement monitoring and observability. Setup steps usingOpenTelemetry are also discussed in that section.

## Plan for testing from day one

Applications/systems/processes should be having testing in place from the very begining. Not only this helps to ensure to avoid costly re-runs/re-work it also helps the team adopt best practices.

See [testing data projects](./DataTesting.md) for details.

## Value proposition - DQ

In addition to having the system available for use, a key measurement of success is meeting business requirements. This means that the system is delivering data to the right audience, with expected levels of *data quality*, frequency and granularity.

==== WIP -Need to add references and code samples
Data quality checks can be performed using mutliple ways:

- Using tools like GreatExpectations
  - Great for running rules on data at rest. Data in transit checks are tough. Validation of entire data set can be very verbose as outputs are in Json.
- Custom coding
  - Need custom development and build, but can be applied for data inflight as well. We can build something like a rule engine - which can attach the results to the record itself for later processing.

- Add integration with Purview
- Greatexpectations usgae (static - aggregate metrics)
- Record level checks (custom dq engine)

## Combining Operations with Business data

- See [Observability section](./MonitoringAndObservabilityUsingOpenTelemetry.md#sample-usecases-for-telemetry-data) for sample use case.

## Visualizations

- The type of visualizations needed are influenced by the [KPIs](#know-the-kpis).
- There should always be a state of the system for both operational systems and business data dashboard.
- [Combine operatonal telemetry/data with business data](#combining-operations-with-business-data). This helps the *continous improvement* activities.

< TO DO>

Adding other aspects of monitoring - user data and security data

- Monitoring hub data as of now is not available
- we can run item execution apis and store those details periodically

see [Data reporting](./DataReporting.md).

## Maintenance tools

Besides satisfying the business requirements, systems should also be built for operational efficiencies in mind. Often times this is an iterative process.  Some of the operantional and maintenance tasks can be automated.

Continuous improvment is a virtuous loop of:

- Good development practices with monitoring in place.
- Monitororing and observality metrics inform the usage of the system and the value being delivered.
- This information should feed into the next cycle of planning/development.

See [maintenance utilities](./MaintenanceUtilities.md) for details. <-- this is a work in progress>

## For more information

- [Engineering fundamentals - MS Learn](https://microsoft.github.io/code-with-engineering-playbook/)
- [Data Playbook - MS Learn](https://learn.microsoft.com/data-engineering/playbook/?branch=main)
