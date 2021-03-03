# Setting up a Continuous Integration pipeline

## 1. Objective

Continuous Delivery (CD) is the process of deploying changes on to a target environment as and when code is integrated to the source repository. CD process usually follows the COntinues Integration (CI) process which is responsible for integrating the code and validating it.

In a modern data engineering environment, Azure Databricks notebooks authored by the developers after integrating into a target branch (like main) is deployed using a CD pipeline. In this sample we will focus on demonstrating a CD pipeline in action.

### 1.1 Scope

As captured in the [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/ci-cd/ci-cd-azure-devops), a typical CI cycle will involve the following steps:

* Deploy
  * Deploy notebooks.
  * Deploy libraries.
* Test: Run automated tests and report results.
* Operate: Programmatically schedule data engineering, analytics, and machine learning workflows.

## 2. Architecture

The below diagram illustrates the architecture of the system covered in this sample.

![alt text](../Common_Assets/Images/IAC_Architecture.png "Logo Title Text 1")

### 2.1 Patterns

Following are the cloud design patterns being used by this sample:

* [External Configuration Store pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/external-configuration-store)
* [Federated Identity pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/federated-identity)
* [Valet Key pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/valet-key)

### 2.2 Anti-patterns

Following are the anti-patterns to be aware of while implementing IAC:

* Placeholder 1
* Placeholder 2

## 3. Implementation

This section captures the implementation details of this sample

### 3.1 Technology stack

The following technologies are used to build this sample:

* Placeholder 1
* Placeholder 2

## 4. How to use this sample

This section holds the information about how this sample can be deployed and verified

### 4.1 Prerequisites

The following are the prerequisites for deploying this sample :

### 4.2 Setup and deployment

Below listed are the steps to deploy this sample :

### 4.3 Deployment validation

The following steps can be performed to validate the correct deployment of this sample

### 4.4 Clean-up

Please follow the below steps to clean up your environment :
