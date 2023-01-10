## Steps To Build a docker image

* Go to the folder : sample-processor ```cd sample-processor```
* Make sure you have a dockerfile and the requirements.txt in the sample-processor folder.
* Make sure that docker is running in your machine.
* Build a docker image by running : ```docker build . -t sample-processor:latest```

*******************************************************************************
### For Local : 
* Ensure you have a folder called data, which has 2 more folders called raw and extracted
* The raw has the  bag file and extracted is the folder wherein you will see a folder with the name of teh bag  file and inside will all be topics  extracted in csv format

### For Cloud
* Ensure you have a storage account, with a container called data and inside same folder structure, raw with bag file(data/raw/samle.bag) and extracted folder(data/extracted) 

********************************************************************************

* After the docker image is built , run docker run with proper mount:
* ```docker run --rm --mount type=bind,source=/Users/pbhimjyani/Desktop/data,target=/data sample-processor:latest bash -c "source /opt/ros/noetic/setup.bash&&python3 /code/rosscript.py /data/raw/sample.bag /data/extracted && rosbag info '/data/raw/sample.bag' > /data/extracted/rosbagInfo.txt"```
* Pls make changes to the path as per your local machine path
* Check the data/extracted and see the extracted topics csv files under a folder with the name of the bag file
* Check the data/extracted. You should see a rosbagInfo.txt 


### Pushing the docker image to Azure Container Regsitry

* Login to acr
* Lets say you have an acr called : ```sharingregistry```
* ```az acr login --name sharingregistry``` 
* Tag your image, lets say you want to push the sample-processor to the acr
* Run this command : ``` docker tag sample-processor:latest  sharingregistry.azurecr.io/sample-processor:v1```
* For Pushing the image to ACR , run : ```docker push sharingregistry.azurecr.io/sample-processor:v1```





