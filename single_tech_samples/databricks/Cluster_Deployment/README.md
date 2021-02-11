# Deploying a secure Azure Databricks cluster on Microsoft Azure
## 1. Objective

It is a recommendation pattern for modern cloud-native applications to automate platform provisioning to achieve consistent, repeatable deployments using Infrastructure as Code (IaC). This practice is highly encouraged by organizations that run multiple environments such as Dev, Test, Performance Test, UAT, Blue and Green production environments, etc. It is also very effective when the production environments are spread across multiple regions across the globe. 

Tools like Azure Resource Manager (ARM), Terraform, and the Azure Command Line Interface (CLI) enable you to declaratively script the cloud infrastructure and use software engineering practices such as testing and versioning while implementing IaC.

This sample will focus on automating provisioning of a secure Azure Databricks cluster using the Infrastructure as Code pattern
### 1.1 Scope
The following list captures the scope of this sample:
1. Provision an Azure Databricks service with network isolation enabled 
1. Configure users/groups to access the Azure Databricks workspace using single sign-on.
1. Apply governance policies to the service at deployment time.
1. Link every instance of the deployment to a deployment definition to centrally control and update deployments.

## 2. Architecture
### 2.1 Patterns
### 2.2 Anti-patterns
## 3. Implementation
### 3.1 Technology stack
## 4. How to use this sample
### 4.1 Prerequisites
### 4.2 Setup and deployment
### 4.3 Deployment validation
### 4.4 Clean-up
