# Microsoft Fabric Utilities

## Python script to upload file in GIT repo to Fabric lakehouse

For config-driven data pipelines or notebooks, the config files are generally stored in the "Files" section of the Fabric Lakehouse. However, the Git integration with Fabric only syncs the lakehouse metadata, not the actual data files. Therefore, the config files must be version controlled outside of Fabric and uploaded to the lakehouse manually. Including this process in the CI/CD pipeline ensures that the latest config files are always available in the lakehouse, and can be promoted to the higher environments.

To facilitate that, the python script [upload-file-to-lakehouse.py](./lakehouse-file-upload/upload-file-to-lakehouse.py) uploads a file from a GIT repository to a Fabric lakehouse. The script uses a service principal with a client secret and uses Azure Data Lake APIs to authenticate and upload the file.

We plan to use this script in the future to automate the process of uploading "config" files from the Git repository to the Fabric Lakehouse as part of the CI/CD process.