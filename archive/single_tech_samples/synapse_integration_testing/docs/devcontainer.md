# Starting the dev container for Parking Sensors Demo

1. Clone the repository
2. Open the repository in vscode
3. Copy the `.envtemplate` to `devcontainer.env` within this folder `single_tech_samples/synapseanalytics/sample3_integration_testing/.devcontainer` and update the values like described [here](../README.md#software-pre-requisites-if-you-use-dev-container)
4. Open the Command Palette (`Ctrl+Shift+P`) and search for `Remote-Containers: Open Folder in Container...`
5. Select `single_tech_samples/synapseanalytics/sample3_integration_testing` and confirm

Note: when pulling latest changes to the devcontainer, ensure you rebuild your container without cache to any changes to the devcontainer.

![OpenFolderInContainer](images/parking_sensors_dev_container_start.gif)

## Troubleshooting

If you encounter below error `Could not find env file` on build, please check if you completed [Step 3](../README.md#software-pre-requisites-if-you-use-dev-container)

![ContainerBuildError](images/devcontainer_build_error.png)
