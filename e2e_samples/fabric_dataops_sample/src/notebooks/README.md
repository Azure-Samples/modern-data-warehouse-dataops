# Microsoft Fabirc Notebook Samples

The notebooks in this section represent sample ETL flows using Microsoft Fabric. We used [Azure Open Datasets](https://learn.microsoft.com/azure/open-datasets/dataset-catalog#population-and-safety) as source data in these examples.

We have two code samples:

1. [City safety data](#sample---city-safety-data) - Standalone ETL using Fabric notebook with unit tests, configuration settings and monitoring using OpenTelemetry.
1. [Covid data](#sample---covid-data) - Fabric notebook which is part of a Fabric data pipeleine. It doesn't include unit tests, monitoring etc.

See below for details.

## Sample - City safety data

Implementation: Refer to [nb-city-safety.ipynb](nb-city-safety.ipynb)

This notebook shows end-to-end tasks involved in the development of a data pipeline/process. We use a Microsoft Fabric notebook to perform some sample ETL operations. We also explain different types of testing, how to create test cases and then run them.

Other details are:

- Reads from ADLS and writes that data to OneLake after a minor transformation.
- Microsoft Open datasets - [City safety data](https://learn.microsoft.com/azure/open-datasets/dataset-catalog#population-and-safety) is the data source used.
- The notebook **doesn't require** a default lakehouse attached and instead uses absolute paths to create/load managed tables.
- The notebook be run from any Fabric workspace as long as proper access to provided to write to the targets(workspace and lakehouse).
- Data can be loaded into:
  - A new table 
  - An existing table in append mode  (by setting - cleanup = False)
  - An existing table in overwrite mode (by setting - cleanup = True)

The diagrams are generated using the code below based on Python's [diagram](https://diagrams.mingrammer.com/) library.

NOTE:

Based on the [OpenTelementry implemtnation options](../../docs/MonitoringAndObservabilityUsingOpenTelemetry.md#consider-openoemetry-setup-options) chosen the target for telemetry data will change:

- The telemetry process flow shows the implementation using *Open Telemetry Collector* Option which has multiple targets.
- If we are using *OpenTelemetry SDK for Azure monitoring* option then AppInsights/LogAlanlytics is the only target for telemetry data.

### Process flow diagram code

```python
from diagrams.azure.storage import StorageAccounts
from diagrams.azure.analytics import SynapseAnalytics, DataExplorerClusters, LogAnalyticsWorkspaces

with Diagram("Process flow", show=False, curvestyle="curved" ):  
    with Cluster("nb-city-safety"):  

        blob_storage = StorageAccounts("City safety data")
        
        log_analytics_workspaces = LogAnalyticsWorkspaces("AppInsights")
        
        with Cluster(label="Microsoft Fabric", direction="LR", graph_attr={"style": "bold", "bgcolor": "grey", "color": "black"}):
            synapse_analytics = SynapseAnalytics("Fabric notebook")
            kusto_db = DataExplorerClusters("OTEL db")
            with Cluster(label="Data Lakehouse", direction="LR", graph_attr={"style": "bold", "bgcolor": "lightblue", "color": "black"}):
                lakehouse_folder = Node(label="lakehouse table", shape="cylinder",  labelloc="b", style="filled", fillcolor="orange", color="black", fontcolor="black")

                
        blob_storage >> synapse_analytics >> [kusto_db, lakehouse_folder, log_analytics_workspaces]
```

![process_flow.png](attachment:c0844d77-f1ee-4813-b714-a01fc91c9f1f.png)

### Telemetry instrumentation flow diagram code

```python
from diagrams import Diagram, Cluster, Node, Edge

# for complete list of attributes: https://graphviz.org/docs/attrs/
with Diagram("OpenTelemetry Trace output", show=False, direction="LR"):  # Graph attributes: https://graphviz.org/docs/graph/ # , curvestyle="curved" 

    with Cluster(label="Trace", graph_attr={"style": "bold", "color": "blue"}): # Cluster attributes: https://graphviz.org/docs/clusters/ 
    
        with Cluster(label="Root span", direction="LR", graph_attr={"style": "bold", "bgcolor": "grey", "color": "black"}):

            root_child_spans = Cluster(label="etl_steps span", direction="LR", graph_attr={"style": "dotted", "bgcolor": "lightblue", "color": "black"}) 

            with root_child_spans:  
                third_child_span = Node(label="City xyz span", shape="promoter",  labelloc="b", style="filled", fillcolor="orange", color="black", fontcolor="black") # node attributes: https://graphviz.org/docs/nodes/
                second_child_span = Node(label="City def span", shape="promoter",  labelloc="b", style="filled", fillcolor="brown", color="black", fontcolor="black")
                first_child_span = Cluster(label="City abc span", graph_attr={"style": "bold", "fontcolor": "blue"})
                
                with first_child_span:  
                    data_activities = Node(label="ingestion acvy | processing acvy| load acvy", shape="record", style="dotted", fontcolor="blue")  

        data_activities >> second_child_span >> third_child_span
```

Here There is a *root span* under which all other child/nested spans are created. Under this *rootspan* - we have one *etl_steps_span* which acts as the parent span for each of the city level span i.e., a span while processing for a city (*city level span*) is created as a nested span under *etl_steps_span*. In our example, this process is pretty isolated and has no upstreams/downstream processes. In cases where is part of a pipeline of processes, then we should ensure to maintain Correlation ids (by using ingecting context from upstream processes). 

TO DO: Give examples here.

![opentelemetry_trace_output.png](attachment:1fbb91dc-3a17-4a84-a308-122709b3511d.png)

## Sample - Covid data

Implementation: Refer to [nb-covid-data.ipynb](./nb-covid-data.ipynb)
