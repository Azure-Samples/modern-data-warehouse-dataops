import logging
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Optional

from azure.ai.evaluation import evaluate
from opentelemetry import trace

from orchestrator.evaluation_config import EvaluatorConfig
from orchestrator.file_utils import load_json_file
from orchestrator.metadata import ExperimentMetadata
from orchestrator.store_results import store_results
from orchestrator.utils import get_output_dirs_by_run_id, new_run_id

tracer = trace.get_tracer(__name__)
logger = logging.getLogger(__name__)


@dataclass
class EvaluationResults:
    results: list
    eval_run_id: str


def evaluate_experiment_result(
    data_path: Path | str,
    evaluators: dict[str, Callable],
    experiment_name: Optional[str] = None,
    job_name: Optional[str] = None,
    evaluator_config: Optional[dict[str, EvaluatorConfig]] = None,
    evaluation_name: Optional[str] = None,
    output_path: Optional[Path] = None,
    tags: Optional[dict] = None,
) -> Any:
    """
    Evaluate the result of an experiment based on the provided metadata.
    Args:
        metadata_path (Path): Path to the metadata file containing experiment details.
        output_path (Optional[Path], optional): Path to store the evaluation results.
            If None, a temporary directory will be used. Defaults to None.
        aml_workspace (Optional[AMLWorkspace], optional): AML workspace
            to store the results. Defaults to None.
    Raises:
        ValueError: If the evaluation data path is missing in the metadata.
        Exception: If the evaluation data file does not exist.
    Returns:
        dict: A dictionary containing the evaluation results.
    """
    # ensure required values are set if uploading to aml
    if tags is None:
        tags = {}
    if job_name is None:
        raise ValueError("When uploading to AML, a job_name is required.")
    if experiment_name is None:
        raise ValueError("When uploading to AML, an experiment_name is required.")

    try:
        # create temp dir if output path is not provided
        temp_dir = None
        if output_path is None:
            temp_dir = Path(tempfile.mkdtemp())
            output_path = temp_dir.joinpath("eval_data.json")

        # evaluate the results
        results = evaluate(
            evaluation_name=evaluation_name,
            data=data_path,
            evaluators=evaluators,
            evaluator_config=evaluator_config,
            output_path=str(output_path),
        )

        store_results(
            experiment_name=experiment_name,
            job_name=job_name,
            tags=tags,
            metrics=results["metrics"],
            artifacts=[output_path],
        )

    # clean up temp dir
    finally:
        if temp_dir is not None:
            shutil.rmtree(temp_dir)

    return results


def evaluate_experiment_results_by_run_id(
    run_id: str,
    write_to_file: bool = False,
) -> EvaluationResults:
    # get list of metadata paths by run_id
    dirs = get_output_dirs_by_run_id(run_id=run_id)
    metadata_paths = []
    for d in dirs:
        metadata_paths.append(d.joinpath(ExperimentMetadata.filename))

    return evaluate_experiment_results_from_metadata(
        metadata_paths=metadata_paths,
        write_to_file=write_to_file,
    )


def evaluate_experiment_results_from_metadata(
    metadata_paths: list[Path],
    write_to_file: bool = False,
) -> EvaluationResults:
    eval_run_id = new_run_id()
    output_path = None
    results = []
    for path in metadata_paths:
        if write_to_file:
            # set output path when writing to file
            output_path = path.parent.joinpath(f"{eval_run_id}{ExperimentMetadata.eval_results_filename_suffix}")

        # load metadata
        metadata_dict: dict = load_json_file(path)
        metadata = ExperimentMetadata.from_dict(metadata_dict)

        # ensure evaluation data file exists
        if metadata.eval_data_path is None:
            raise ValueError("Missing eval data path")
        else:
            eval_data_path = path.parent.joinpath(metadata.eval_data_path)
            if not eval_data_path.exists():
                raise Exception("Eval data file does not exist")

        # load evaluators and config
        evaluators, evaluator_config = metadata.load_evaluators_and_config()

        # update tags
        tags = {
            "run_id": metadata.run_id,
            "variant.name": metadata.variant_name,
            "eval_run_id": eval_run_id,
        }

        if metadata.evaluation and metadata.evaluation.tags:
            tags.update(metadata.evaluation.tags)

        # run the evaluation
        result = evaluate_experiment_result(
            data_path=eval_data_path,
            evaluators=evaluators,
            experiment_name=metadata.experiment_name,
            job_name=metadata.variant_name,
            evaluator_config=evaluator_config,
            output_path=output_path,
            tags=tags,
        )
        results.append(result)

    return EvaluationResults(results=results, eval_run_id=eval_run_id)
