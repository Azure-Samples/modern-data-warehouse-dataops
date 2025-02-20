from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from opentelemetry import trace
from orchestrator.aml import AMLWorkspace
from orchestrator.evaluation_loader import load_evaluation
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
    aml_workspace: Optional[AMLWorkspace] = None,
    write_to_file: bool = False,
) -> EvaluationResults:
    # get list of metadata paths by run_id
    dirs = get_output_dirs_by_run_id(run_id=run_id)
    metadata_paths = []
    for d in dirs:
        metadata_paths.append(d.joinpath(ExperimentMetadata.filename))

    return evaluate_experiment_results_from_metadata(
        metadata_paths=metadata_paths,
        aml_workspace=aml_workspace,
        write_to_file=write_to_file,
    )


def evaluate_experiment_results_from_metadata(
    metadata_paths: list[Path],
    aml_workspace: Optional[AMLWorkspace] = None,
    write_to_file: bool = False,
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

        result = evaluation.run(aml_workspace=aml_workspace, output_path=output_path)
        results.append(result)

    return EvaluationResults(results=results, eval_run_id=eval_run_id)
