"""Task configuration for creating container workloads.
"""
from core.config import Settings, getSettings

def getTaskDefinitions() -> list:
    """Creates a map of extraction tasks required for a measurement.

    Returns:
        list: A list of task definitions.
    """
    settings: Settings = getSettings()

    return [
        {
            "name": "ExtractBagData",
            "imageName": f"{settings.AZ_ACR_NAME}.azurecr.io/sample-processor:latest",
            "command": "python3 /code/app.py --inputFile ##INPUTFILE## --outputPath ##OUTPUTPATH##",
            "taskDependencies": None,
            "exitJobOnFailure": True,
        },
        {
            "name": "GenerateBagMetadata",
            "imageName":  f"{settings.AZ_ACR_NAME}.azurecr.io/sample-processor:latest",
            "command": "rosbag info \"##INPUTFILE##\" > ##OUTPUTPATH##/meta-data-info.txt",
            "taskDependencies": None,
            "exitJobOnFailure": True,
        }
    ]
