# Infrastructure as Code

## Getting Started

1. az login
1. ./setup.sh
1. Run terraform init with the output from step 2
1. terraform validate && terraform plan && terraform apply

### Example: Run the following commands to setup `Terraform` state

```bash
# Setup Terrafrom infrastructure
az login
./setup.sh rg-my-terraform stmyterraform kv-myterraform japaneast
```

> ### Use the output from the above command to setup credentials for the next command (`terraform apply`)
> 
> __example output__
> ```bash
> # Use the Azure cli to login and allow access to Azure Key Vault from the cli
> 
> az login 
> 
> # When initializing your local environment
> 
> cd terraform/live/dev
> 
> terraform init -backend-config="storage_account_name=stmyterraformdev" -backend-config="container_name=terraform-state" -backend-config="access_key=$(az keyvault secret show --name tfstate-storage-key-dev --vault-name kv-myterraform --query value -o tsv)" -backend-config="key=terraform.tfstate"
> 
> # When running "apply", "destroy", etc. commands:
> 
> cd terraform/live/dev
> 
> export ARM_CLIENT_ID="$(az keyvault secret show --name tf-sp-id --vault-name kv-myterraform --query value -o tsv)"
> export ARM_CLIENT_SECRET="$(az keyvault secret show --name tf-sp-secret --vault-name kv-myterraform --query value -o tsv)"
> export ARM_SUBSCRIPTION_ID="$(az keyvault secret show --name tf-subscription-id --vault-name kv-myterraform --query value -o tsv)"
> export ARM_TENANT_ID="$(az keyvault secret show --name tf-tenant-id --vault-name kv-myterraform --query value -o tsv)"
> ```

### Example: Run the following commands to create the `myapp` infrastructure.

```bash
cd terraform/live/dev

export ARM_CLIENT_ID="$(az keyvault secret show --name tf-sp-id --vault-name kv-myterraform --query value -o tsv)"
export ARM_CLIENT_SECRET="$(az keyvault secret show --name tf-sp-secret --vault-name kv-myterraform --query value -o tsv)"
export ARM_SUBSCRIPTION_ID="$(az keyvault secret show --name tf-subscription-id --vault-name kv-myterraform --query value -o tsv)"
export ARM_TENANT_ID="$(az keyvault secret show --name tf-tenant-id --vault-name kv-myterraform --query value -o tsv)"

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

* [Cobalt project](https://github.com/microsoft/cobalt)
