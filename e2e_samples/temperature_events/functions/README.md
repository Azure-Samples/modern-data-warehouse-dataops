# Temperature Functions App

## Getting Started

**Prerequisites:**

- Dotnet core 3.1
- Azure Functions 3.0

**Deploy Steps:**

The following deploys the Azure Function Apps. Ensure you are in `e2e_samples/temperature_events/functions/`.

1. `az login`
1. Deploy `DeviceIdFilter` using `func` cli
1. Deploy `TemperatureFilter` using `func` cli

### Deploy all functions to Azure

- Assuming infra was deployed to Azure via Terraform.
  - Check the [Infra README](../infra/README.md) for details.
- If you need to install the `Azure Functions Core Tools`, see the `GitHub` [README](https://github.com/Azure/azure-functions-core-tools/blob/dev/README.md)

```bash
# NOTE: Be sure to set MY_APP=myapp to what you set in the Infra setup
# e.g. MY_APP=bob2

# Deploy to Azure
az login
cd TemperatureEventsProj

MY_APP=myapp
func azure functionapp publish func-DeviceIdFilter-${MY_APP}-dev --csharp
func azure functionapp publish func-TemperatureFilter-${MY_APP}-dev --csharp
```
