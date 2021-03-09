# Deploying a secure Azure Databricks cluster on Microsoft Azure

## 1. Objective

It is a recommended pattern for modern cloud-native applications to automate platform provisioning to achieve consistent, repeatable deployments using Infrastructure as Code (IaC). This practice is highly encouraged by organizations that run multiple environments such as Dev, Test, Performance Test, UAT, Blue and Green production environments, etc. IAC is also very effective in managing deployments when the production environments are spread across multiple regions across the globe.

Tools like Azure Resource Manager (ARM), Terraform, and the Azure Command Line Interface (CLI) enable you to declaratively script the cloud infrastructure and use software engineering practices such as testing and versioning while implementing IaC.

This sample will focus on automating the provisioning of a secure Azure Databricks cluster using the Infrastructure as Code pattern

### 1.1 Scope

The following list captures the scope of this sample:

1. Provision an Azure Databricks service with network isolation enabled
1. Configure users/groups to access the Azure Databricks workspace using single sign-on.
1. Apply governance policies to the service at deployment time.
1. Link every instance of the deployment to a deployment definition to centrally control and update deployments.

## 2. Architecture

The below diagram illustrates the architecture of the system covered in this sample.

![alt text](../Common_Assets/Images/IAC_Architecture.png "Logo Title Text 1")

### 2.1 Patterns

Following are the cloud design patterns being used by this sample:

* [External Configuration Store pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/external-configuration-store)
* [Federated Identity pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/federated-identity)
* [Health Endpoint Monitoring pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/health-endpoint-monitoring)
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
