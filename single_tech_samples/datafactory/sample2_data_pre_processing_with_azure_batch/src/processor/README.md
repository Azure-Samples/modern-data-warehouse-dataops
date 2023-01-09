## Steps To Build a docker image

* Go to the folder : sample-processor ```cd sample-processor```
* Make sure you have a dockerfile and the requirements.txt in the sample-processor folder.
* Make sure that docker is running in your machine.
* Build a docker image by running : ```docker build . -t sample-processor:latest```

*******************************************************************************
### For Local : 
* Ensure you have a folder called data, which has 2 more folders called inputDir and outputDir
* The inputDir has the  bag file and outputDir is the folder wherein you will see a folder with the name of teh bag  file and inside will all be topics  extracted in csv format

### For Cloud
* Ensure you have a storage account, with a container called data and inside same folder structure, inputDir with bag file(data/inputDir/samle.bag) and outputDir folder(data/outputDir) 

********************************************************************************

* After the docker image is built , run docker run with proper mount:
* ```docker run --rm --mount type=bind,source=/Users/pbhimjyani/Desktop/data,target=/data sample-processor:latest bash -c "source /opt/ros/noetic/setup.bash&&python3 /code/rosscript.py /data/inputDir/sample.bag /data/outputDir"```
* Pls make changes to the path as per your local machine path
* Check the data/outputDir and see the extracted topics csv files


### Pushing the docker image to Azure Container Regsitry

* Login to acr
* Lets say you have an acr called : ```registry27```
* ```az acr login --name registry27``` 
* Tag your image, lets say you want to push the sample-processor to the acr
* Run this command : ``` docker tag sample-processor:latest  registry27.azurecr.io/sample-processor:v1```
* For Pushing the image to ACR , run : ```docker push registry27.azurecr.io/sample-processor:v1```





