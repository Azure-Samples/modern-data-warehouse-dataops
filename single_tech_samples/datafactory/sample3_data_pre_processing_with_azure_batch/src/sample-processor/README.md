# Sample Processor

This is a sample image which is build from ros:noetic base image. It extracts the contents of a given bag file to an output path dirctory. Both the input file path and the output path are provided as parameters.

## Build and Push the docker image to Azure Container Regsitry(ACR)

1. Go to the folder `src/sample-processor`

    ```shell
    cd ./single_tech_samples/datafactory/sample3_data_pre_processing_with_azure_batch/src/sample-processor
    ```

2. Login to your Azure Account

    ```shell
    az login
    az account set -s <YOUR-SUBSCRIPTION_ID>
    ```

3. Set the following variables in `deploy-processor.sh`

    ```shell
    RESOURCE_GROUP_NAME="<YOUR-RESOURCE-GROUP-NAME>"
    STORAGE_ACCOUNT_NAME="<YOUR-ADLS-STORAGE-ACCOUNT>"
    CONTAINER_REGISTRY_NAME="<YOUR-ACR-NANME>"
    ```

    Note: Refer to [deployed resources](../../deploy/terraform/README.md#deployed-resources) to get your resource names.

4. Give execute permissions to script `chmod +x deploy-processor.sh`

5. Run `./deploy-processor.sh`

[Back to deployment steps](../../README.md#setup-and-deployment)

### Testing your image locally [OPTIONAL]

Run the following command, which mounts src/sample-processor/data to your container.

`Make sure to update <YOURPATH> with your clonned directory path`

```shell
docker run --rm --mount type=bind,source=<YOURPATH>/src/sample-processor/data,target=/data sample-processor:latest bash -c "source /opt/ros/noetic/setup.bash&&python3 /code/app.py -i /data/raw/sample-data.bag -o /data && rosbag info '/data/raw/sample-data.bag' > /data/extracted/rosbagInfo.txt"
```

Once this command runs successfully, you will see the output in the `src/sample-processor/data/output` folder.
