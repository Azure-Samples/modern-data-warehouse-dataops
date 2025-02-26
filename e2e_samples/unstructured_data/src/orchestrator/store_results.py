import logging
from pathlib import Path
from typing import Optional

import mlflow

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def store_results(
    experiment_name: str,
    job_name: str,
    tags: Optional[dict[str, str]] = None,
    metrics: Optional[dict[str, int | float]] = None,
    artifacts: Optional[list[Path]] = None,
) -> None:
    mlflow.set_tracking_uri("databricks")

    # Define the experiment name
    experiment_name = f"/Shared/{experiment_name}"

    # Create or set the experiment
    mlflow.set_experiment(experiment_name)

    # Start a new run
    with mlflow.start_run(run_name=job_name):
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

    print(f"Finished recording experiment: {experiment_name}.")
