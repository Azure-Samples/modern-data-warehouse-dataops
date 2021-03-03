# Setting up a Continuous Integration pipeline
## 1. Objective
As per Microsoft Documentation, Continuous Integration (CI) is the process of automating the build and testing of code every time code changes are committed to the version control. CI is a best practice encouraged in agile development teams as it enables team members to work in isolation, and then integrate their changes with the team’s codebase while minimizing regressions.

This pattern is also applicable to development teams responsible for authoring notebooks deployed on Azure Databricks. This sample focuses on demonstrating the Continues Integration pipeline for Azure Databricks notebooks. 

### 1.1 Scope
As captured in the [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/ci-cd/ci-cd-azure-devops), a typical CI cycle will involve the following steps:
* Code
  * Develop code and unit tests in a Databricks notebook or using an external IDE.
  * Manually run tests.
  * Commit code and tests to a git branch.
* Build
  * Gather new and updated code and tests.
  * Run automated tests.
  * Build libraries and non-notebook Apache Spark code.
* Release: Generate a release artifact.

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