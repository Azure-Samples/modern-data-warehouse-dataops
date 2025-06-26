# Naming conventions for Fabric E2E sample

This document describes the naming conventions for the Fabric E2E sample. It includes the naming conventions for the following:

- Git Folders
- Scripts (python, shell, powershell etc.)
- Configuration files (.yml, .json, .cfg etc.)
- Azure/Fabric resources

## Status

Accepted

## Context

As the Fabric E2E sample is a complex solution with multiple components, it is important to have a consistent naming convention for the various components. This will help in better organization and management of the solution. It would also help multiple developers to work on the solution without any confusion.

## Proposal details

### GitHub files naming convention

| Item Type | Convention | Additional Details | Example |
| --- | --- | --- | --- |
| Folders | snake_case | Use lowercase and "_" | `fabric_dataops_sample`, `dataops_pipeline` |
| Markdown files | UPPERCASE or snake_case | Use UPPERCASE only for standard files such as README, CONTRIBUTING etc. | `README.md`, `adr_naming_convention.md` |
| Python scripts | snake_case | Use lowercase and "_" | `setup_fabric_environment.py` |
| Python notebooks | snake_case | Start with "xx_" where x=[0, 9] | `00_setup.ipynb`, `02_standardize.ipynb`, `03_transform.ipynb` |
| Shell scripts | snake_case | Use lowercase and "_" | `deploy_infrastructure.sh` |
| PowerShell scripts | PascalCase | Use "-" and "verb-noun" structure | `Set-DeploymentPipelines.ps1` |
| Images (diagrams, screenshots etc.) | kebab-case | Use lowercase and "-" | `graph-api-permission.png`, `fabric-architecture.drawio`|
| YAML files | kebab-case | Use lowercase and "-" | `deploy-infra.yml` |
| JSON files | kebab-case | Use lowercase and "-" | `fabric-config.json` |
| Configuration files | kebab-case | Use lowercase and "-" | `dataops-config.cfg` |
| Wheel files | [pep-427](https://peps.python.org/pep-0427/) | {distribution}-{version}(-{build tag})?-{python tag}-{abi tag}-{platform tag}.whl | `azure_monitor_opentelemetry-1.6.1-py3-none-any.whl` |

### Variables/Functions naming convention

| Variable Type | Convention | Additional Details | Example |
| --- | --- | --- | --- |
| Environment variables | UPPER_SNAKE_CASE | Use uppercase and "_" | `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET` |
| Shell script variables to read Terraform output | `tf_`snake_case | Prefix with "tf_" | `tf_storage_account_name` |
| Shell/Python script variables (in general) | snake_case | Use lowercase and "_" | `storage_account_name` |
| PowerShell script variables | `$`camelCase |  | `$storageAccountName` |
| Shell/Python Functions | snake_case | Use lowercase and "_" | `get_storage_account_name` |
| PowerShell Functions | PascalCase | Use "Verb-Noun" structure | `Get-StorageAccountName` |
| Terraform variables | snake_case | Use lowercase and "-" | `environment_name` |

### Azure/Fabric resource naming convention

| Resource/Item Name | Convention | Default Name |
| --- | --- | --- |
| Resource Group | `rg-*` | N/A - passed |
| ADLS Gen2 Account | `st*` | `st<base-name>` |
| Storage container name | N/A | "main" |
| Azure Key Vault | `kv-*` | `kv-<base-name>` |
| Entra Security Group | `sg-*` | N/A - passed |
| Log Analytics Workspace | `la-*` | `law-<base-name>` |
| Application Insights | `appi-*` | `appi-<base-name>` |
| Fabric Capacity | `cap*` | `cap<base-name-trimmed>` |
| Fabric Workspace | `ws-*` | `ws-<base-name>` |
| Fabric Lakehouse | `lh_*` | `lh_<base-name>` |
| Fabric Notebooks | `nb-*` | "nb-setup", "nb-standardize", "nb-transform" |
| Fabric Pipelines | `pl-*` | "pl-main.json" |
| Fabric Environment | `env-*` | `env-<base-name>` |
| Fabric Custom Spark Pool | `sprk-*` | `sprk-<base-name>` |
| Azure DevOps Variable Group | `vg-*` | `vg-<base-name>` |

## Decision

To be agreed

## Next steps

If accepted:

- The naming convention will be followed for all existing components in the Fabric E2E sample.
- The naming convention will be followed for all new components added to the Fabric E2E sample.
- The main [README.md](./../README.md) will be updated with the default resource naming.
- The team will discuss the possibility of adopting the naming convention for the whole MDE repository.
