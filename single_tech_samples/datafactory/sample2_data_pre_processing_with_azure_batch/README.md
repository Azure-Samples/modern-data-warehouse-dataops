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
  - [2.3. Deployed Resources](#23-deployed-resources)
  - [2.4. Deployment validation and Execution](#24-deployment-validation-and-execution)
  - [2.5. Clean-up](#25-clean-up)
- [3. Troubleshooting](#3-troubleshooting)

## 1. Solution Overview

This solution demonstrates how we can do data pre-processing by running Azure Batch container workloads from Azure Data Factory.

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

Ideally in actual production scenarios, there will be two ADLS accounts representing raw and extarcted zones, for the simplcity case we will have the raw and the extarcted zones in the same ADLS account. Pipeline will pick the ros bag file from the raw zone and send it for extraction to Azure Batch where the file can be extracted simultaneously by one or more processors. In this sample we will be a single sample-processor which will be packaged as a docker image and pushed to container registry. Azure batch will this image spin a container and perform the extraction and store the extarcted contents back to extracted zone. Once the extraction is completed ADF pipeline can proceed with the next step to process this extracted data or invoke other pipelines.

Details about [how to run the pipeline](#24-deployment-validation-and-execution) can be found in the later sections of this document.

### 1.3. Architecture

The below diagram illustrates the high level design showing the ADF and the azure batch integration for running container workloads on azure batch:

![alt text](images/adf-batch-integration-design.svg "Design Diagram")
#### **Architectur Design Components**
- **Raw Zone:** This is an ADLS account where the ingested data lands.
- **Extracted Zone:** This is an ADLS account where the extracted data will be stored.
- **ADF Pipeline:** This is an ADF pipeline which can have a scheduled trigger to pick data from raw zone and sends it to azure batch for extraction.
- **Azure Batch:**  It will extract the bag file data and stored the extracted contents to extracted zone. Azure Batch has following components:
    - **Orchestrator Pool:** This is a batch pool which runs a batch application, see [sample here]() on an ubuntu node. ADF pipeline uses a custom activity to invoke this application. This application acts as an orchestrator for creating jobs and tasks and monitoring those for completion on execution pool described below.
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

The following are the prerequisites for deploying this sample:



### 2.1.1 Software Prerequisites

1. [Terraform (any version >1.2.8)](https://developer.hashicorp.com/terraform/downloads)
2. [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### 2.2. Setup and deployment
1. Refer [this](./deploy/terraform/README.md) documentaion for steps to setup a new environment.

### 2.3. Deployment validation and Execution

The following steps can be performed to validate the correct deployment and execution of the sample:


## 3. Troubleshooting
