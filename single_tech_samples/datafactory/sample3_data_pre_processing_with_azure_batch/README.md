# Running container workloads from Azure Data Factory on Azure Batch <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [1. Solution Overview](#1-solution-overview)
  - [1.1. Scope](#11-scope)
  - [1.2. Use Case](#12-use-case)
  - [1.3. Architecture](#13-architecture)
  - [1.4. Technologies used](#14-technologies-used)
- [2. How to use this sample](#2-how-to-use-this-sample)
  - [2.1. Prerequisites](#21-prerequisites)
    - [2.1.1 Software Prerequisites](#211-software-prerequisites)
  - [2.2. Setup and deployment](#22-setup-and-deployment)  
  - [2.3. Deployment validation and Execution](#23-deployment-validation-and-execution)
  - [2.4. Clean-up](#24-clean-up)

## 1. Solution Overview

The solution demonstrates the process of performing data pre-processing by running Azure Batch container workloads from Azure Data Factory.

Azure Batch is a great option for data pre-processing. However, there are certain technical challenges and limitations when it comes to processing large files, autoscaling batch nodes and triggering batch workloads from Azure Data Factory. Some of these challenges and limitations are explained below:

### Auto-scaling issues(slow spin-up times for new nodes) 

To process your workloads processor code need to be deployed on the Azure Batch nodes, which means all the dependencies which are required by your application are to be installed on the batch node. Azure Batch provides you with startup task which can be used to install the required dependencies, but if the required dependencies are too many then it will delay the node readiness and will impact your autoscaling as every new node which gets spun up will take time to get ready for processing your workloads. This setup time can vary from 3-30 minutes depending on the list of dependencies your processor code requires.

```plaintext
In such cases it is best practice to containerize your application and run container work loads on Azure Batch. 
```

### Working with large files 

When processing large files it does not makes sense to download the large files on to the batch nodes from storage account and then extract the contents and upload those back to the storage account. This way you need to ensure your nodes have enough storage attached to them or you may require to do some kind of cleansing to free the space after the job is done and you will be spending extra time in the downloading and uploading of contents to storage account.

```plaintext
The best practice here is, you can mount your storage accounts on to the batch nodes and access the data directly. However one thing to be noted here is NFS mounts are not supported on windows nodes. For more details see Mounting storage accounts via NFS
```

### Triggering azure batch container workloads from Azure datafactory 

Azure datafactory does not support triggering batch container workloads directly via its [custom activity](https://learn.microsoft.com/en-us/azure/data-factory/transform-data-using-custom-activity). The below [architecture](#13-architecture) explains how to over come this limitation.

This sample will focus on provisioning an Azure Batch account, Azure Data Factory and other required resources where you can run the ADF pipeline to see how the data pre-processing can be done on huge volume of data in an efficient and scalable manner.  

### 1.1. Scope

The following list captures the scope of this sample:

1. Provision an ADF, Azure Batch and required storage acounts and other resources.
2. The following services will be provisioned as a part of this sample setup:
   1. V-Net with one subnet
   2. Azure Data Factory
   3. Azure Batch Account
   4. ADLS account with a sample data(.bag) file
   5. Azure Storage account for azure batch resources
   6. Key Vault
   7. User Assigned Managed Identity

Details about [how to use this sample](#2-how-to-use-this-sample) can be found in the later sections of this document.

### 1.2. Use Case

For our sample use case we have a sample [ros bag file](http://wiki.ros.org/Bags/Format) in an ADLS account and will be picked by ADF pipeline for pre-processing via Azure Batch.

Ideally in actual production scenarios, there will be two ADLS accounts representing raw and extarcted zones, for the simplcity case we will have the raw and the extarcted zones in the same ADLS account. Pipeline will pick the ros bag file from the raw zone and send it for extraction to Azure Batch where the file can be extracted simultaneously by one or more processors. In this sample we will be using a single `sample-processor` which will be packaged as a docker image and pushed to container registry. Azure batch will use this image to spin a container and perform the extraction and store the extarcted contents back to extracted zone. Once the extraction is completed ADF pipeline can proceed with the next step to process this extracted data or invoke other pipelines.

![use-case](images/pre-processing-usecase.map.drawio.svg)

Details about [how to run the pipeline](#24-deployment-validation-and-execution) can be found in the later sections of this document.

### 1.3. Architecture

The below diagram illustrates the high level design showing the ADF and the azure batch integration for running container workloads on azure batch:

![alt text](images/adf-batch-integration-design.svg "Design Diagram")

#### **Architecture Design Components**

- **Raw Zone:** This is an ADLS account where the ingested data lands.

- **Extracted Zone:** This is an ADLS account where the extracted data will be stored.

- **ADF Pipeline:** This is an ADF pipeline which can have a scheduled trigger to pick data from raw zone and sends it to azure batch for extraction.

- **Azure Batch:**  It will extract the bag file data and stored the extracted contents to extracted zone. Azure Batch has following components:

  - **Orchestrator Pool:** This is a batch pool which runs a batch application, see [sample here](src/orchestrator-app/README.md) on an ubuntu node. ADF pipeline uses a custom activity to invoke this application. This application acts as an orchestrator for creating jobs and tasks and monitoring those for completion on execution pool described below.

  - **Execution Pool:** This is a a batch pool which is responsible for running container work loads. This pool has start up task configuration where it mounts the raw and extracted ADLS zones as NFS mounts to its nodes and when containers are spinned to process the actual workloads and the same mounts are mounted to containers as well via container run options. Orchestrator pool creates jobs and tasks for execution pool.

      ADLS storage mounts on execution pool nodes and containers will help containers to process large files without downloading the locally.

- **Application Insights:** It monitors the health of execution and orchestrator pool nodes. We can integrate the application insights with azure batch application and the container images for end to end tracing of jobs.

- **Azure Container Registry(ACR):**  In this sample execution pool is configured with a azure container registry to pull container images, but we can have any container registry configured.

- **Managed Identity:** This is a user assigned managed identity which will be assigned to both of the batch pools and batch pool will use it to access any other required resources like container registry, keyvault, storage account etc.

### 1.4. Technologies used

The following technologies are used to build this sample:

- [Azure Data Factory](https://azure.microsoft.com/en-in/products/data-factory/)
- [Azure Batch](https://azure.microsoft.com/en-us/products/batch)
- [Azure Storage(ADLS)](https://azure.microsoft.com/en-au/services/storage/data-lake-storage/)
- [NFS Mounts](https://learn.microsoft.com/en-us/azure/storage/blobs/network-file-system-protocol-support-how-to)

## 2. How to use this sample

This section holds the information about usage instructions of this sample.

### 2.1. Prerequisites

1. [Github account](https://github.com/)
2. [Azure Account](https://azure.microsoft.com/en-gb/free/)
   - *Permissions needed*:  The ability to create and deploy to an Azure [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)

   - Active subscription with the following [resource providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers) enabled:

     - Microsoft.Storage
     - Microsoft.DataFactory
     - Microsoft.KeyVault
     - Microsoft.Batch
     - Microsoft.ContainerRegistry

#### 2.1.1 Software Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed on the local machine

   - *Installation instructions* can be found [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. [Terraform](https://www.terraform.io/)
   - *Installation instructions* can be found [here](https://developer.hashicorp.com/terraform/downloads)
3. [Docker Desktop](https://www.docker.com/get-started/)
   - *Installation instructions* can be found [here](https://www.docker.com/products/docker-desktop/)
4. For Windows users,
   1. Option 1: [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
   2. Option 2: Use the devcontainer published [here](./.devcontainer) as a host for the bash shell, it has all the pre-requisites installed.
      For more information about Devcontainers, see [here](https://code.visualstudio.com/docs/remote/containers).

### 2.2. Setup and deployment

1. Clone this repository.

   ```shell
   git clone https://github.com/Azure-Samples/modern-data-warehouse-dataops.git
   ```

2. [Deploy all the azure resources required for the sample](deploy/terraform/README.md)
3. [Deploy a sample ADF pipeline.](deploy/adf/README.md)
4. [Publish a sample-processor image to your azure container registry.](src/sample-processor/README.md)
5. [Deploy a sample orchestrator app to azure batch pool.](src/orchestrator-app/README.md)

### 2.3. Deployment validation and Execution

The following steps can be performed to validate the correct deployment and execution of the sample:

1. Go to your azure portal and select your resource group.
2. Select the azure data factory, and click on Launch Studio (Azure Datafactory Studio).
3. Select Author pipreines.

   ![Author PIpeline](images/author-pipelines.png)

4. From the pipelines open sample-pipeline.

   ![sample pipeline](images/sample-pipeline.png)

5. From the pipelines options Add trigger select Trigger now.
6. Once the pipeline runs, it will create a job for orchestartor pool with the name `adfv2-orchestratorpool` and a task under it to invoke orchestrator app `extract.py` entry file.
7. Orchestrator app will create an extract job and a couple of tasks for execution pool.

   ![jobs](images/jobs.png)

   ```shell
   Note: Those tasks are actually the container works loads and sample-processor image deployed as a part of deploymemt steps will be used for executing the tasks.
   ```

8. Once the execution pool tasks are completed, a sample rosbag file will be extracted to the `extracted/output` folder and a ros metadata info(`meta-data-info.txt`) will be generated in the `extarcted` folder.

   ![pipeline output](images/pipeline-output.png)

9. Your ADF piepline will be marked as completed.

   ![pipeline run](images/pipeline-run.png)

### 2.4. Clean-up

Please follow the steps in the [clean-up section](deploy/terraform/README.md)

### Resources

- [Parallel processing with Azure Batch.](https://learn.microsoft.com/en-us/azure/batch/batch-technical-overview#run-parallel-workloads)

- [Autoscaling with Azure Batch](https://learn.microsoft.com/en-us/azure/batch/batch-automatic-scaling)

- [Running Azure Batch from Azure Data Factory(ADF)](https://learn.microsoft.com/en-us/azure/batch/tutorial-run-python-batch-azure-data-factory)
