# IaC Questionnaire

## 1. Does your cluster require Single sign-on (SSO) and enforce Credential passthrough

Control access to Azure Data Lake Storage using users’ Azure Active Directory credentials.
Authenticate users using Azure Active Directory. This is always enabled and is the only option. If you use a different IdP, federate your IdP with Azure Active Directory.

## 2. Do you need to control access to the ADB workspace using Role-based access control?

Control access to clusters, jobs, data tables, APIs, and workspace resources such as notebooks, folders, jobs, and registered models.

## 3. Does your organization's security policies enforce network isolation for ADB workspaces?

 VNet injection: Deploy an Azure Databricks workspace in your own VNet that you manage in your Azure subscription. Enables you to implement custom network configuration with custom Network Security Group rules.

## 4. Does your organization's security policies enforce Secure cluster connectivity?

Enable secure cluster connectivity on the workspace, which means that your VNet’s Network Security Group (NSG) has no open inbound ports and Databricks Runtime cluster nodes have no public IP addresses. Also known as “No Public IPs.” You can enable this feature for a workspace during deployment. This feature is in Public Preview.

## 5. Does your organization's security policies enforce restrictions on where (specific network/machine) the ADB workspace is accessed from?

Enforce network location of workspace users.

## 6. Does your organization's security policies require custom key encryption for ADB files?

Encrypt notebook data using an Azure Key Vault key that you manage. Encrypt the Databricks File Storage (DBFS) root using an Azure Key Vault key that you manage. DBFS is a distributed file system mounted into an Azure Databricks workspace and available on Azure Databricks clusters.

## 7. Is there a requirement to limit the user's ability to configure the ADB clusters based on a set of rules?

Cluster policies let you enforce particular cluster settings (such as instance types, attached libraries, compute cost) and display different cluster-creation interfaces for different user levels.

## 8. Does your organization have requirements around sharing the deployment template/script across multiple users/teams

Should we use Azure Deployment Templates?

## 9. Will it benefit for your IT department to to have centralized control over the deployment scripts and policies?

Should we use Azure Blueprints?

## 10. Are there any restrictions on geographical regions where your organizations can deploy ADB workspaces?

Should we use azure policies
