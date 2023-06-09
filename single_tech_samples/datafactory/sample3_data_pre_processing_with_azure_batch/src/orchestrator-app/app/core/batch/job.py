"""This class is for managing batch job operations.
"""
import logging

from logging import Logger
import datetime
import time
from azure.batch import BatchServiceClient
import azure.batch.models as batchModels
import azure.batch.models._batch_service_client_enums as batchEnums
from utils.batchclient import getBatchClient
from core.config import Settings, getSettings


class Job:
    """This class is for managing batch job operations.
    """
    settings: Settings
    log: Logger
    batchServiceClient: BatchServiceClient
    
    def __init__(self, settings:Settings=getSettings(), log:Logger=logging.getLogger(__name__), batchClient: BatchServiceClient= getBatchClient()) -> None:
        self.batchServiceClient=batchClient
        self.log=log
        self.settings=settings
        
    def createJob(self, jobId: str, poolId: str, useTaskDependency: bool=False, onTaskFailure: batchEnums.OnTaskFailure = batchEnums.OnTaskFailure.perform_exit_options_job_action):
        """Creates a job with the specified ID, associated with the specified pool.

        Args:
            jobId (str): Job Id
            poolId (str): name of the pool
            useTaskDependency (bool, optional): A boolean value for dependent tasks in the job
            onTaskFailure (batchEnums.OnTaskFailure, optional): An action to be taken on the running job if task fails.
        """
        self.log.info(f'Creating job [{jobId}]...')

        job = batchModels.JobAddParameter(
            id=jobId,
            uses_task_dependencies=useTaskDependency,
            on_task_failure= onTaskFailure,
            on_all_tasks_complete=batchEnums.OnAllTasksComplete.terminate_job,
            pool_info=batchModels.PoolInformation(pool_id=poolId))

        self.batchServiceClient.job.add(job)

    def addTasksToJob(self, jobId: str, taskList: list):
        """Add tasks to a job.

        Args:
            jobId (str): Job Id to which tasks need to be added
            taskList (list): List of tasks to be added.
        """
        if taskList is None or len(taskList)==0:
            raise RuntimeError("Expected one or more tasks to be added.")
        
        self.log.info(f'Adding {len(taskList)} tasks to job [{jobId}]...')
        self.batchServiceClient.task.add_collection(jobId, taskList)
    
    def getFailedTasks(self, jobId: str):
        """Get failed tasks for a job

        Args:
            jobId (str): Job Id

        Returns:
            _type_: A list of failed tasks.
        """
        tasks = self.batchServiceClient.task.list(
            job_id=jobId     
        )
        failedTasks = [task for task in tasks if
                                task.execution_info.exit_code != 0]
        return failedTasks
    
    def checkIfJobisCompleted(self, jobId: str) -> bool:
        """Checks if the given job is completed or not.

        Args:
            jobId (str): Job Id

        Returns:
            _type_: Returns true if the job is already completed.
        """
        jobs = self.batchServiceClient.job.list(            
            job_list_options=batchModels.JobListOptions(
                filter=f"id eq '{jobId}'"
            )
        )
        completedJobs = [job for job in jobs if job.state == batchEnums.JobState.completed]
        
        return len(completedJobs) > 0
    
    def monitorJobsToComplete(self, jobs: list,
                               timeout: datetime.timedelta):
        """Monitor all taks for the given jobs for completion.

        Args:
            jobs (list): List of job Ids
            timeout (datetime.timedelta): A threshold time for monitoring the given jobs. 
            This threshold will preventing running the program for an infinite time.
        """
        timeout_expiration = datetime.datetime.now() + timeout

        self.log.info(f"Monitoring all tasks for 'Completed' state, timeout in {timeout}")

        while datetime.datetime.now() < timeout_expiration:
            print('.',end='')
            
            # Get all tasks from all jobs
            allIncompleteTasks=[]
            for job in jobs:
                # Check if job is completed then skip its task monitoring
                isCompleted = self.checkIfJobisCompleted(job)
                if isCompleted:
                    continue
                tasks = self.batchServiceClient.task.list(job)    
                incompleteTasks = [task for task in tasks if
                                task.state != batchModels.TaskState.completed]
                if len(incompleteTasks) > 0:
                    allIncompleteTasks.append(incompleteTasks)
                
            if not allIncompleteTasks:
                return True
            time.sleep(5)

        raise RuntimeError("ERROR: Tasks did not reach 'Completed' state within "
                          "timeout period of " + str(timeout))