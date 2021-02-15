# Temperature Functions App

## Getting Started

1. az login
1. Deploy `DeviceIdFilter` using `func` cli
1. Deploy `TemperatureFilter` using `func` cli

### __Example__ Deploy all functions for `myapp` app to `Azure`

> Assuming infra was deployed to Azure via IaC.
>
> Check the [Infra README](../Infra/README.md) for details.
>
> If you need to install the `Azure Functions Core Tools`, see the `GitHub` [README](https://github.com/Azure/azure-functions-core-tools/blob/dev/README.md)

```bash
# Deploy to Azure

az login
cd TemperatureEventsProj
MY_APP=myapp
func azure functionapp publish func-DeviceIdFilter-${MY_APP}-dev
func azure functionapp publish func-TemperatureFilter-${MY_APP}-dev
```
