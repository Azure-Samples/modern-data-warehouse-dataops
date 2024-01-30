# Infrastructure as Code

## Getting Started

**Prerequisites:**

- Terraform > 0.14.7
- Azure cli > 2.19.1

**Deploy Steps:**

The following deploys the Azure base infrastructure for the Temperature Events sample. Ensure you are in `e2e_samples/temperature_events/infra/`.

1. `az login`
2. `./setup.sh`
3. Run terraform init with the output from step 2
4. `terraform validate && terraform plan && terraform apply`

### #1 `az login`

```bash
> az login
```

Authenticate with the Azure CLI, to ensure you are able interact with your Azure account.
<https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli>

### #2 `./setup.sh` to create Terraform support resources

This script will a resource group, with 2 resources (Key Vault and Storage) to track the secrets and state of your infrastructure. It will also create a new Service Principal with contributor permissions, for the Terraform app to use later.

```bash
# Setup infrastructure for Terrafrom state & secrets.
# NOTE: Change the values to a unique name for your account.
# ./setup.sh <resource group> <storage name> <Key Vault name> <region>
az login
./setup.sh rg-my-terraform stmyterraform kv-myterraform eastus2
```

Keep note of the output from `./setup.sh`. The output will be used in the next command

### #3 Run terraform init with the output from step 2

Use the output from the last command, to initialise the Terraform state files and store them in the Azure storage & Key Vault resources created in step 2.

```bash
# Note: This is an example, use the exact output given to you in step 2.
az login
cd terraform/live/dev

terraform init -backend-config="storage_account_name=stmyterraformdev" -backend-config="container_name=terraform-state" -backend-config="access_key=$(az keyvault secret show --name tfstate-storage-key-dev --vault-name kv-myterraform --query value -o tsv)" -backend-config="key=terraform.tfstate"
```

### #4 Use `terraform apply` to create the sample resources

Run the following commands to deploy the sample infrastructure.  
**Note:** Pick a globally unique name, do not use the value `"name=myapp"`.  e.g. `"name=bob123"`

```bash
# NOTE: enter your own unique value instead of `myapp`
terraform plan -var "name=myapp" -out=/tmp/myapp
terraform apply /tmp/myapp
```

## Before sending PR

1. Run [pre-commit](https://pre-commit.com/#install)
1. Make sure this README.md is updated

## Directory Structure/Provisioned resources

```zsh
$tree -d
.
└── terraform
    ├── live
    │   └── dev
    └── modules
        ├── eventhubs
        ├── functions
        └── services
```

```bash
$ terraform state list
    module.service.azurerm_app_service_plan.function_app
    module.service.azurerm_application_insights.app_insights
    module.service.azurerm_key_vault_access_policy.keyvault_policy[0]
    module.service.azurerm_key_vault_access_policy.keyvault_policy[1]
    module.service.azurerm_key_vault_secret.kv_appinsights_conn_string
    module.service.azurerm_key_vault_secret.kv_eventhub_conn_string[0]
    module.service.azurerm_key_vault_secret.kv_eventhub_conn_string[1]
    module.service.azurerm_key_vault_secret.kv_eventhub_conn_string[2]
    module.service.azurerm_key_vault_secret.kv_eventhub_conn_string[3]
    module.service.azurerm_resource_group.rg
    module.service.module.eventhubs[0].azurerm_eventhub.eventhub
    module.service.module.eventhubs[0].azurerm_eventhub_authorization_rule.eventhub_authorization_rule
    module.service.module.eventhubs[0].azurerm_eventhub_consumer_group.function_consumer_group
    module.service.module.eventhubs[0].azurerm_eventhub_namespace.eventhub
    module.service.module.eventhubs[1].azurerm_eventhub.eventhub
    module.service.module.eventhubs[1].azurerm_eventhub_authorization_rule.eventhub_authorization_rule
    module.service.module.eventhubs[1].azurerm_eventhub_consumer_group.function_consumer_group
    module.service.module.eventhubs[1].azurerm_eventhub_namespace.eventhub
    module.service.module.eventhubs[2].azurerm_eventhub.eventhub
    module.service.module.eventhubs[2].azurerm_eventhub_authorization_rule.eventhub_authorization_rule
    module.service.module.eventhubs[2].azurerm_eventhub_consumer_group.function_consumer_group
    module.service.module.eventhubs[2].azurerm_eventhub_namespace.eventhub
    module.service.module.eventhubs[3].azurerm_eventhub.eventhub
    module.service.module.eventhubs[3].azurerm_eventhub_authorization_rule.eventhub_authorization_rule
    module.service.module.eventhubs[3].azurerm_eventhub_consumer_group.function_consumer_group
    module.service.module.eventhubs[3].azurerm_eventhub_namespace.eventhub
    module.service.module.functions[0].azurerm_function_app.function_app
    module.service.module.functions[0].azurerm_storage_account.storage
    module.service.module.functions[1].azurerm_function_app.function_app
    module.service.module.functions[1].azurerm_storage_account.storage
    module.service.data.azurerm_client_config.current
    module.service.azurerm_key_vault.kv
    module.service.azurerm_key_vault_access_policy.keyvault_set_get_policy
```

### Live

This is the entry point of terraform script. Terraform scripts under each environment (i.e. dev) calls service module with corresponding configurations.

### Modules

Modules are the building blocks of resources. A module is a wrapper with more than one resources. In this project, module needs to contain more than 1 resources.

## References

- [Cobalt project](https://github.com/microsoft/cobalt)
