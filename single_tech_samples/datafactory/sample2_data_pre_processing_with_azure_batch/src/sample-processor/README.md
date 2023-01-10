## Sample Rosbag Processor
This is a sample image which is buid from ros:noetic base image. It extracts the contents of a given bag file to an output path dircetory. Both the input file path and the output path are provided as parameters.

### Steps To Build a docker image

* Go to the folder : sample-processor ```cd src/sample-processor```
* Build a docker image by running : ```docker build . -t sample-processor:latest```

### Testing your image locally

Run the following command, which mounts src/sample-processor/data to your container.

`Make sure to update <YOURPATH> with your clonned directory path`

    ```docker run --rm --mount type=bind,source=<YOURPATH>/src/sample-processor/data,target=/data sample-processor:latest bash -c "source /opt/ros/noetic/setup.bash&&python3 /code/rosscript.py /data/raw/sample.bag /data/extracted && rosbag info '/data/raw/sample.bag' > /data/extracted/rosbagInfo.txt"
    ```
Once this command rund successfully, you will see the output in the `src/sample-processor/data/extracted` folder.


### Pushing the docker image to Azure Container Regsitry(ACR)

* Login to acr
 ```
 az acr login --name sharingregistry
 ``` 
* Tag your image as `sample-processor:latest` 
  
``` 
docker tag sample-processor:latest  sharingregistry.azurecr.io/sample-processor:v1
```

* Push your image to ACR
 ```
 docker push sharingregistry.azurecr.io/sample-processor:v1
 ```





