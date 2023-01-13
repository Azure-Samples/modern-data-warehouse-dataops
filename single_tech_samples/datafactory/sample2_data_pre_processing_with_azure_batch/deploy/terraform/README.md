## 1. How to use this sample

This section holds the information about usage instructions of this sample.

### 1.1 Prerequisites

The following are the prerequisites for deploying this sample:

1. [Terraform (any version >1.2.8)](https://developer.hashicorp.com/terraform/downloads)
2. [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### 1.2. Setup and deployment
1. Clone this repository
2. Go to the directory containing all the terraform scripts to setup a new environment

```
cd ./single_tech_samples/datafactory/sample2_data_pre_processing_with_azure_batch/deploy/terraform 
```

3. Login to the Azure Account you wish to use for the deployment. 
4. Create a resource group for the new environemnt in your subscription. This can be done using the following az cli command 

```
az group create --name {resourceGroupName} --location {location}
```

5. In the terraform.tfvars file, enter the values required according to your prefernece.

6. After the resource group has been successfully set up and you have configered all the variables in terraform.tfvars file, run the following terraform commands to deploy all the resources in your resource group. 

```
terraform init
terraform plan 
terraform apply
```

### 1.3. Deployed Resources

The following resources will be deployed as a part of this sample once the script is executed:
- Azure Data Factory
- Azure Batch
- Azure Data Lake Storage
- Azure Blob Store
- Virtual Network with a subnet
- Azure Container Registry
- Azure Key Vault
- User Assigned Managed Idnetity dedicated to Azure batch 

### 1.4. Clean-up the whole infrastructure

Please follow the below steps to clean up your environment :

1. Go to the terraform directory 

```
cd ./single_tech_samples/datafactory/sample2_data_pre_processing_with_azure_batch/deploy/terraform 
```
 
2. Run the following command to clean up your environment and destroy all the resources

```
terraform destroy
```

## 2. Best Practices 

It is ideal to configure a storage account to use as a remote backend for your terraform state files. For simplicity's sake, we have not configured a remote backed and by default terraform will use the local backend to save all the state files. 
For learning more about configuring a remote backend and its advantages, follow this [link](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
