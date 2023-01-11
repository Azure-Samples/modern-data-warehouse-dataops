"""Task configuration for creating container workloads.
"""


def getTaskDefinitions() -> list:
    """Creates a map of extraction tasks required for the rosbag topics extraction.

    The command key has 2 commands separated by && :
    First part, Calls the app.py which takes 2 input parameters rawPath and extractedPath
    Second part, calls rosbag info on the rosbag file which is at the rawPath and stores the output in rosbagInfo.txt in the extractedPath 
    
    Returns:
        list: A list of task definitions.
    """
    return [
        {
            "name": "RosProcessorTask",
            "imageName": "sharingregistry.azurecr.io/sample-processor:latest",
            "command": "python3 /code/app.py -rPath ##RAWPATH## -ePath  ##EXTRACTEDPATH## && rosbag info \"##RAWPATH##\" > ##EXTRACTEDPATH##/rosbagInfo.txt",
            "taskDependencies": None,
            "exitJobOnFailure": True,
        }
    ]
