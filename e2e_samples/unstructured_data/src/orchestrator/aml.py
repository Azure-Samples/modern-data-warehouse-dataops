from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import mlflow
from azureml.core import Workspace
from orchestrator.logging import get_logger

logger = get_logger(__name__)


@dataclass
class AMLWorkspace:
    """
    AMLWorkspace class represents an Azure Machine Learning workspace.

    Attributes:
        subscription_id (str): The subscription ID for the Azure account.
        resource_group (str): The resource group in which the workspace is located.
        workspace_name (str): The name of the Azure Machine Learning workspace.
    """

    subscription_id: str
    resource_group: str
    workspace_name: str


def store_results(
    experiment_name: str,
    job_name: str,
    aml_workspace: AMLWorkspace,
    tags: Optional[dict[str, str]] = None,
    metrics: Optional[dict[str, int | float]] = None,
    artifacts: Optional[list[Path]] = None,
) -> None:
    """
    Store results of an evaluation in Azure Machine Learning
        (AML) workspace using MLflow.
    Args:
        experiment_name (str): The name of the experiment to log results to.
        job_name (str): The name of the job/run to log.
        aml_workspace (AMLWorkspace): The AML workspace configuration object
        tags (dict[str, str], optional): A dictionary of tags to associate with the run.
        metrics (dict[str, int | float], optional): A dictionary of metrics to log.
        artifacts (list[Path], optional): A list of file paths to log as artifacts.
    Returns:
        None
    """
    workspace = Workspace.get(
        subscription_id=aml_workspace.subscription_id,
        resource_group=aml_workspace.resource_group,
        name=aml_workspace.workspace_name,
    )
    tracking_url = workspace.get_mlflow_tracking_uri()
    # # Set our tracking server uri for mlflow logging
    mlflow.set_tracking_uri(tracking_url)

    # Create an AML Experiment with the provided name if the experiment does not exist
    experiment = mlflow.get_experiment_by_name(experiment_name)
    if experiment is None:
        mlflow.create_experiment(experiment_name)

    # Associate with experiment
    mlflow.set_experiment(experiment_name=experiment_name)

    # Start the run
    with mlflow.start_run(run_name=job_name):
        logger.info(f"Logging {job_name} to MLFlow on AML")

        # Add tags
        if tags is not None:
            for tag, description in tags.items():
                mlflow.set_tag(tag, description)

        # Log metrics or other information
        if metrics is not None:
            for metric, value in metrics.items():
                mlflow.log_metric(metric, value)

        # Upload artifacts
        if artifacts is not None:
            for artifact in artifacts:
                mlflow.log_artifact(str(artifact))

        logger.info("Completed uploading result to AML.")

    # End run
    mlflow.end_run()
