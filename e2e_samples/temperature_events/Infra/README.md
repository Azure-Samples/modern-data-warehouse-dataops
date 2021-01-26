# Infrastructure as Code

## Getting Started (Local)

1. az login
1. ./setup.sh
1. Run terraform init with the output from step 2
1. terraform validate && terraform plan && terraform apply

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
        ├── keyvault
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
    module.service.module.keyvault.data.azurerm_client_config.current
    module.service.module.keyvault.azurerm_key_vault.kv
    module.service.module.keyvault.azurerm_key_vault_access_policy.keyvault_set_get_policy
```

### Live

This is the entry point of terraform script. Terraform scripts under each environment (i.e. dev) calls service module with corresponding configurations.

### Modules

Modules are the building blocks of resources. A module is a wrapper with more than one resources. In this project, module needs to contain more than 1 resources.

## References

* [Cobalt project](https://github.com/microsoft/cobalt)
