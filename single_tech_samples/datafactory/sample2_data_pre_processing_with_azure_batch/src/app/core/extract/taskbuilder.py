"""This class is for building extration tasks.
"""
from logging import Logger, getLogger

from core.config import Settings, getSettings
from core.batch.task import Task
from core.extract.extracttasks import getTaskDefinitions


class TaskBuilder:
    """This class is for building extration tasks."""

    settings: Settings
    log: Logger
    task: Task

    def __init__(self, settings: Settings, task: Task, log: Logger = getLogger(__name__)) -> None:
        self.settings = settings
        self.task = task
        self.log = log

    def createExtractionTasks(
        self, rawPath: str, extractedPath: str
    ) -> list:
        """This method creates required extraction tasks for individual bag file.

        Args:
            rawPath (str): Actual path of the bag file to be extracted
            extractedPath (str): Destination path of extracted topics of bags in csv format

        Returns:
            list: A list of tasks.
        """
        tasks = []  # array with 1 item
        # Read taskdefinitions to create a task list for the given file.
        for taskDef in getTaskDefinitions():
            command = self.createCommand(commandTemplate=taskDef["command"],
                                         rawPath=rawPath,
                                         extractedPath=extractedPath
                                         )
            requiredSlots = 1
            exitJobOnFailure = False
            taskDependencies = None
            if "taskSlotsRequired" in taskDef:
                requiredSlots = taskDef["taskSlotsRequired"]
            if "exitJobOnFailure" in taskDef:
                exitJobOnFailure = taskDef["exitJobOnFailure"]
            if "taskDependencies" in taskDef:
                taskDependencies = taskDef["taskDependencies"]
            tasks.append(
                self.task.createTask(
                    name=taskDef["name"],
                    command=command,
                    dependentTaskIds=taskDependencies,
                    image=taskDef["imageName"],
                    requiredSlots=requiredSlots,
                    exitJobOnFailure=exitJobOnFailure,
                )
            )
        return tasks

    def createCommand(
        self,
        commandTemplate: str,
        rawPath: str,
        extractedPath: str
    ):
        """This method replaces the templated params with the actual params.

        Args:
            commandTemplate (str): template command with param placeholders
            rawPath (str): Actual path of the bag file to be extracted
            extractedPath (str): Destination path of extracted topics of bags in csv format

        Returns:
            _type_: A command string with actual params
        """
        return (commandTemplate.replace("##RAWPATH##", str(rawPath)).replace("##EXTRACTEDPATH##", str(extractedPath)))
