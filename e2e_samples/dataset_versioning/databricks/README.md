# Azure Databricks Credential Passthrough
In this sample, we are using the Azure Databricks Credential Passthrough feature to securely access datalake.
You can also use the storage access key to access datalake, but you will need to store it in keyvault and create a databricks secret scope to access the key. 

Credential Passthrough is a practice that is more recommended by the official doc because it ensures that only people who have access to the datalake storage can access it from databricks. If you use storage access key, then anyone will be able to access datalake.

When using a High Concurrency Cluster with credential passthrough, this cluster can be shared among multiple users. The cluster will take the identity of whoever is using the cluster and access datalake. However according to the limitations mentioned in [this doc](https://docs.microsoft.com/en-us/azure/databricks/security/credential-passthrough/adls-passthrough#--limitations), looks like MLflow on high concurrency clusters will not work well. Since we will be using MLFlow in our project, we will avoid using the high concurrency cluster and just use the standard clusters. For Standard Clusters, only a single user's identity can be tied to each cluster, so every user will need to create their own cluster when using credential passthrough. 

## Credential Passthrough vs Service Principal
The [official doc](https://docs.microsoft.com/en-us/azure/databricks/security/data-governance#secure-access-to-azure-data-lake-storage) mentioned:

- Will you be accessing your data in a more interactive, ad-hoc way, perhaps developing an ML model or building an operational dashboard? In that case, we recommend that you use Azure Active Directory (Azure AD) credential passthrough.
- Will you be running automated, scheduled workloads that require one-off access to the containers in your data lake? Then using service principals to access Azure Data Lake Storage is preferred.

## Setup Credential Passthrough
Check the [Credential Passthrough Documentation](https://docs.microsoft.com/en-us/azure/databricks/security/credential-passthrough/adls-passthrough) for more details and how to setup credential passthrough. Basically, you need to check the "Enable credential passthrough for user-level data access" checkbox when creating the cluster in the advanced settings, and use these lines in your databricks notebook:

```
configs = {
  "fs.azure.account.auth.type": "CustomAccessToken",
  "fs.azure.account.custom.token.provider.class": spark.conf.get("spark.databricks.passthrough.adls.gen2.tokenProviderClassName")
}
```
Then, you will be able to access datalake.