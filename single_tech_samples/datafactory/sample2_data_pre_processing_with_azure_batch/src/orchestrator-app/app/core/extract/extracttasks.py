"""Task configuration for creating container workloads.
"""


def getTaskDefinitions() -> list:
    """Creates a map of extraction tasks required for a measurement.

    Returns:
        list: A list of task definitions.
    """
    return [
        {
            "name": "ExtractBagData",
            "imageName": "sharingregistry.azurecr.io/sample-processor:latest",
            "command": "python3 /code/app.py --rawPath ##INPUTFILE## --extractedPath  ##OUTPUTPATH##",
            "taskDependencies": None,
            "exitJobOnFailure": True,
        },
        {
            "name": "GenerateBagMetadata",
            "imageName": "sharingregistry.azurecr.io/sample-processor:latest",
            "command": "rosbag info \"##INPUTFILE##\" > ##OUTPUTPATH##/meta-data-info.txt",
            "taskDependencies": None,
            "exitJobOnFailure": True,
        }
    ]
