"""This class is for managing batch task operations.
"""
import os
import azure.batch.models as batchModels
from core.config import Settings, getSettings
import azure.batch.models._batch_service_client_enums as batchEnums


class Task:
    """This class is for managing batch task operations."""

    mountConfig: str

    def __init__(self) -> None:        
        self.mountConfig = f"--mount source=/data,target=/data,type=bind"

    def createTask(
        self,
        name: str,
        command: str,
        dependentTaskIds: list = None,
        image: str = None,
        requiredSlots: int = 1,
        exitJobOnFailure: bool = False,
    ):
        """Creates a task for the given params.

        Args:
            name (str): name of the task and will be used as task Id.
            command (str): Actual command to be executed.
            dependentTaskIds (list, optional): A list of dependent tasks, if any.
            image (str, optional): _description_. Name of the image, if the given command is for a container.
            requiredSlots(int, optional): By default 1 task slot will be allocated, but can be overriden with the given number.
            exitJobOnFailure(bool, optional): By defualt if task fails, job will continue to process other tasks.
            If set to true job will terminate and will terminate the remaining tasks as well.
        Returns:
            _type_: A TaskAddParameter object.
        """
        
        task = batchModels.TaskAddParameter(
            id=name,
            required_slots=requiredSlots,
            constraints=batchModels.TaskConstraints(
                max_task_retry_count=2
            ),
            command_line=f"/bin/bash -c '{command}'",
            user_identity=batchModels.UserIdentity(
                auto_user=batchModels.AutoUserSpecification(
                    elevation_level=batchModels.ElevationLevel.admin,
                    scope=batchModels.AutoUserScope.pool,
                )
            ),
        )
        # Add container settings if the image has value.
        if image is not None:
            task.container_settings = batchModels.TaskContainerSettings(
                image_name=image,
                container_run_options=self.mountConfig,
            )
        # Add task dependency if the dependent tasks are provided.
        if dependentTaskIds is not None:
            task.depends_on = batchModels.TaskDependencies(task_ids=dependentTaskIds)
        if exitJobOnFailure:
            task.exit_conditions = batchModels.ExitConditions(
                exit_code_ranges=[
                    batchModels.ExitCodeRangeMapping(
                        start=1,
                        end=255,
                        exit_options=batchModels.ExitOptions(
                            dependency_action=batchEnums.DependencyAction.block,
                            job_action=batchEnums.JobAction.terminate,
                        ),
                    )
                ]
            )
        else:
            task.exit_conditions = batchModels.ExitConditions(
                default=batchModels.ExitOptions(job_action=batchEnums.JobAction.none)
            )

        return task
