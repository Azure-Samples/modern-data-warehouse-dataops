## Sample Processor
This is a sample image which is buid from ros:noetic base image. It extracts the contents of a given bag file to an output path dirctory. Both the input file path and the output path are provided as parameters.

### Steps To build a docker image

* Go to the folder `src/sample-processor` 

```
cd ./single_tech_samples/datafactory/sample2_data_pre_processing_with_azure_batch/src/sample-processor
```

* Build a docker image by running : 
```
docker build . -t sample-processor:latest
```

### Testing your image locally

Run the following command, which mounts src/sample-processor/data to your container.

`Make sure to update <YOURPATH> with your clonned directory path`

```
docker run --rm --mount type=bind,source=<YOURPATH>/src/sample-processor/data,target=/data sample-processor:latest bash -c "source /opt/ros/noetic/setup.bash&&python3 /code/app.py /data/raw/sample.bag /data/extracted && rosbag info '/data/raw/sample-data.bag' > /data/extracted/rosbagInfo.txt"
```

Once this command runs successfully, you will see the output in the `src/sample-processor/data/extracted` folder.


## Pushing the docker image to Azure Container Regsitry(ACR)

* Login to your Azure Account

```
az login
az account set -s <YOUR-SUBSCRIPTION_ID>
```

* Login to your Azure Container Registry(ACR)
 
```
az acr login --name <YOUR-ACR-NANME>
```

* Tag your image as `sample-processor:latest` 
  
``` 
docker tag sample-processor:latest  <YOUR-ACR-NANME>.azurecr.io/sample-processor:latest
```

* Push your image to ACR

 ```
 docker push <YOUR-ACR-NANME>.azurecr.io/sample-processor:latest
 ```

Run the following script

```
RESOURCE_GROUP_NAME="<YOUR-RESOURCE-GROUP-NAME>"
STORAGE_ACCOUNT_NAME="<YOUR-ADLS-STORAGE-ACCOUNT>"

#Add your client ip to access storage account.
IP_ADDRESS=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
az storage account network-rule add -g $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --ip-address $IP_ADDRESS

#Upload sample file
az storage blob upload -f "data/raw/sample-data.bag" -c data/raw --account-name "$STORAGE_ACCOUNT_NAME"

#Create extracted path.
az storage blob directory create -c data -d extracted --account-name "$STORAGE_ACCOUNT_NAME"
```
[Back to deployment steps](../../README.md)




