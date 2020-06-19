---
page_type: sample
languages:
- python
products:
- Azure
- Azure-Data-factory
- Azure-Databricks
- Azure-Data-Lake-Gen2
description: "Code samples showcasing how to apply DevOps concepts to the Modern Data Warehouse Architecture leveraging different Azure Data Technologies."
---

## DataOps for the Modern Data Warehouse

This repository contains numerous code samples and artifacts on how to apply DevOps principles to data pipelines built according to the [Modern Data Warehouse (MDW)](https://azure.microsoft.com/en-au/solutions/architecture/modern-data-warehouse/) architectural pattern on [Microsoft Azure](https://azure.microsoft.com/en-au/). 

The samples are either focused on a single azure service or showcases an end to end data pipeline solution built according to the MDW pattern. Each sample contains code and artifacts relating to:
- Build and Release Pipelines (CI/CD)
- Testing
- Observability / Monitoring

## Contents

### How to use the Repo

Pre-requisites:
- [Docker](https://www.docker.com/)
- [VSCode](https://code.visualstudio.com/)

1. Rename `.envtemplate` to `devcontainer.env` and update the values.
2. Open the project inside the vscode devconatiner
3. Run `az login` in the vscode terminal and follow the steps to login
4. To provision the infrastructure required for [**Parking Sensor Solution**](e2e_samples/parking_sensors/), in the vscode terminal, cd to `e2e_samples/parking_sensors/` and run `./deploy.sh`

### End to End samples
   - [**Parking Sensor Solution**](e2e_samples/parking_sensors/) - This sample solution demonstrates an end-to-end data pipeline following the MDW architecture, along with a corresponding CI/CD process. 
     - This was solution was presented at [NDC Sydney 2019](https://ndcsydney.com/). See [here](https://www.youtube.com/watch?v=Xs1-OU5cmsw) for the presentation which includes a detailed walkthrough of the solution.
     - **Data Pipeline Architecture**
         ![Architecture](docs/images/architecture.PNG?raw=true "Architecture")
     - **Build and Release Process**
         ![CI/CD](docs/images/CI_CD_process.PNG?raw=true "CI/CD")


### Single Technology Samples
   - [Azure SQL](single_tech_samples/azuresql/)

   Coming soon..
   - [Data Factory](single_tech_samples/datafactory/)
   - [Azure Databricks](single_tech_samples/databricks/)
   - [Stream Analytics](single_tech_samples/streamanalytics/)
   - [Azure Synapse (formerly SQLDW)](single_tech_samples/synapseanalytics/)
   - [CosmosDB](single_tech_samples/cosmosdb/)


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
