"""This class schedules extraction jobs.
"""
import time
from core.config import Settings
from core.batch.task import Task
from core.batch.job import Job
from core.extract.taskbuilder import TaskBuilder


class ExtractScheduler:
    """This class schedules extraction jobs."""

    job: Job
    task: Task
    taskBuilder: TaskBuilder
    settings: Settings

    def __init__(self, job: Job, task: Task, settings: Settings) -> None:
        self.job = job
        self.task = task
        self.settings = settings
        self.taskBuilder = TaskBuilder(settings=settings, task=task)

    def scheduleExtraction(self, rawPath: str, extractedPath: str, poolId: str) -> list:
        """This method schedules jobs/tasks for sample rosbag extraction.

        Args:
            rawPath (str): Actual path of the bag file to be extracted
            extractedPath (str): Destination path of extracted topics of bags in csv format
            poolId (str): Pool Id which will run the extraction jobs

        Returns:
            list: List of jobs created for the extracttion of the bag file. Currently the list has just one job.
           
        """
        jobs = []

        timestamp = time.strftime("%Y%m%d-%H%M%S")
        jobId = f"Ext_Bag_{timestamp}"  # name of job

        # Create a job that will run the tasks for extracting a bag file.
        self.job.createJob(jobId=jobId, poolId=poolId, useTaskDependency=True)

        # Create extraction tasks for the job
        tasks = self.taskBuilder.createExtractionTasks(
            rawPath=rawPath,
            extractedPath=extractedPath
        )

        # Add the tasks to the job.
        self.job.addTasksToJob(jobId=jobId, taskList=tasks)
        jobs.append(jobId)
        return jobs
