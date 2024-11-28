# Naming convention for Fabric E2E sample

This document describes the naming convention for the Fabric E2E sample. It includes the naming convention for the following:

- Git Folders
- Scripts (python, shell, powershell etc.)
- Configuration files (.yml, .json, .cfg etc.)
- Azure/Fabric resources

## Status

Proposed

## Context

As the Fabric E2E sample is a complex solution with multiple components, it is important to have a consistent naming convention for the various components. This will help in better organization and management of the solution. It would also help multiple developers to work on the solution without any confusion.

## Proposal details

### GitHub files naming convention

| Item Type | Convention | Additional Details | Example |
| --- | --- | --- | --- |
| Folders | snake_case | Use lowercase and "_" | `fabric_dataops_sample`, `dataops_pipeline` |
| Markdown files | snake-case | Use lowercase and "_" | "README.md", `adr_naming_convention.md` |
| Python scripts | snake_case | Use lowercase and "_" | `setup_fabric_environment.py` |
| Shell scripts | snake_case | Use lowercase and "_" | `deploy_infrastructure.sh` |
| PowerShell scripts | PascalCase | Use "-" and "verb-noun" structure | `Set-DeploymentPipelines.ps1` |
| Images (diagrams, screenshots etc.) | kebab-case | Use lowercase and "-" | `graph-api-permission.png`, `fabric-architecture.drawio`|
| YAML files | kebab-case | Use lowercase and "-" | `deploy-infra.yml` |
| JSON files | kebab-case | Use lowercase and "-" | `fabric-config.json` |
| Configuration files | kebab-case | Use lowercase and "-" | `dataops-config.cfg` |
| Wheel files | [pep-427](https://peps.python.org/pep-0427/) | {distribution}-{version}(-{build tag})?-{python tag}-{abi tag}-{platform tag}.whl | `azure_monitor_opentelemetry-1.6.1-py3-none-any.whl` |

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
| Fabric Environment | `env-*` | `env-<base-name>` |
| Fabric Notebooks | `nb-*` | "nb-010-setup.ipynb", "nb-020-standardize.ipynb", "nb-030-transform.ipynb" |
| Fabric Pipelines | `pl-*` | "pl-000-main.json" |
| Fabric Environment | `env-*` | `env-<base-name>` |
| Fabric Custom Pool | `sprk-*` | `sprk-<base-name>` |
| Azure DevOps Variable Group | `vg-*` | `vg-<base-name>` |

## Decision

To be agreed

## Next steps

If accepted, the naming convention details will be included in the CONTRIBUTING.md file.
