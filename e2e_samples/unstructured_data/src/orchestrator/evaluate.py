from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from opentelemetry import trace
from orchestrator.evaluation_loader import load_evaluation
from orchestrator.evaluation_wrapper import MlflowType
from orchestrator.logging import get_logger
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import get_output_dirs_by_run_id, new_run_id

tracer = trace.get_tracer(__name__)
logger = get_logger(__name__)


@dataclass
class EvaluationResults:
    results: list
    eval_run_id: str


def evaluate_experiment_results_by_run_id(
    run_id: str,
    write_to_file: bool = False,
    mlflow_type: Optional[MlflowType] = None,
) -> EvaluationResults:
    # get list of metadata paths by run_id
    dirs = get_output_dirs_by_run_id(run_id=run_id)
    metadata_paths = []
    for d in dirs:
        metadata_paths.append(d.joinpath(ExperimentMetadata.filename))

    return evaluate_experiment_results_from_metadata(
        metadata_paths=metadata_paths,
        write_to_file=write_to_file,
        mlflow_type=mlflow_type,
    )


def evaluate_experiment_results_from_metadata(
    metadata_paths: list[Path],
    write_to_file: bool = False,
    mlflow_type: Optional[MlflowType] = None,
) -> EvaluationResults:
    eval_run_id = new_run_id()
    output_path = None
    results = []
    for path in metadata_paths:
        if write_to_file:
            output_path = path.parent.joinpath(f"{eval_run_id}{ExperimentMetadata.eval_results_filename_suffix}")

        evaluation = load_evaluation(
            metadata_path=path,
            eval_run_id=eval_run_id,
        )

        result = evaluation.run(output_path=output_path, mlflow_type=mlflow_type)
        results.append(result)

    return EvaluationResults(results=results, eval_run_id=eval_run_id)
