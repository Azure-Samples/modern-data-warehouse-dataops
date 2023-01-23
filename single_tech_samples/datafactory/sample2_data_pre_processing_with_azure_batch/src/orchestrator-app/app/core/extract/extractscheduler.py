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

    def __init__(self, job: Job, task: Task) -> None:
        self.job = job
        self.task = task
        self.taskBuilder = TaskBuilder(task=task)

    def scheduleExtraction(self,inputFile:str, outputPath:str, poolId: str) -> list:
        """This method schedules jobs/tasks for measurement extraction.

        Args:
            inputFile (str): Input bag file path which is to be extracted
            outputPath (str): Output path where extracted contents of bag file will be stored.
            poolId (str): Pool Id which will run the extraction jobs

        Returns:
            list: List of jobs created for the given measurement.
        """
        jobs = []
        
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        jobId = f"extraction_job_{timestamp}"

        # Create a job that will run the tasks for extracting a bag file.
        self.job.createJob(jobId=jobId, poolId=poolId, useTaskDependency=True)

        # Create extraction tasks for the job
        tasks = self.taskBuilder.createExtractionTasks(
            fileName=inputFile,
            outputPath=outputPath
        )

        # Add the tasks to the job.
        self.job.addTasksToJob(jobId=jobId, taskList=tasks)
        jobs.append(jobId)
        return jobs
