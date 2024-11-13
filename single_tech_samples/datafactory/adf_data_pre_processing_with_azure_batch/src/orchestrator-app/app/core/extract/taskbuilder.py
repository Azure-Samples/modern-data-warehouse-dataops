"""This class is for building extration tasks.
"""
from logging import Logger, getLogger

from core.batch.task import Task
from core.extract.extracttasks import getTaskDefinitions


class TaskBuilder:
    """This class is for building extration tasks."""

    log: Logger
    task: Task

    def __init__(self, task: Task, log: Logger = getLogger(__name__)) -> None:
        self.task = task
        self.log = log

    def createExtractionTasks(
        self, fileName: str, outputPath: str
    ) -> list:
        """This method creates required extraction tasks for individual bag file.

        Args:
            fileName (str): Full path of the file.
            outputPath (str): Output path where the extracted data will be stored.

        Returns:
            list: A list of tasks.
        """
        tasks = []
        # Read taskdefinitions to create a task list for the given file.
        for taskDef in getTaskDefinitions():
            self.log.info(f"Creating {taskDef['name']} for [{fileName}]")
            command = self.createCommand(
                commandTemplate=taskDef["command"],
                fileName=fileName,
                outputPath=outputPath
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
        fileName: str,
        outputPath: str
    ):
        """This method replaces the templated params with the actual params.

        Args:
            commandTemplate (str): template command with param placeholders
            fileName (str): Actual file name
            outputPath (str): output path

        Returns:
            _type_: A command string with actual params
        """
        return (
            commandTemplate.replace("##INPUTFILE##", fileName)
            .replace("##OUTPUTPATH##", outputPath)
        )
