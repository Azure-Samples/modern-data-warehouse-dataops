import importlib
import logging
import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable

from opentelemetry import trace
from orchestrator.experiment_config import ExperimentConfig, VariantConfig
from orchestrator.file_utils import write_json_file, write_jsonl_file
from orchestrator.metadata import ExperimentMetadata

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

tracer = trace.get_tracer(__name__)


@dataclass
class ExperimentWrapper:
    """
    A wrapper class for running experiments and managing their metadata.
    Attributes:
        experiment (Callable): The experiment to be run.
        metadata (ExperimentMetadata): Metadata associated with the experiment.
    Methods:
        __init__(exp_config: ExperimentConfig, variant_config: VariantConfig,
            run_id: str):
            Initializes the ExperimentWrapper with the given configuration and run ID.
        run(data_filename: str = "none", line_number: int | str = "none", **kwargs)
            -> dict:
            Runs the experiment with the provided data and additional keyword arguments.
        write_results(output_dir: Path, results: list, is_eval_data: bool = False)
            -> str:
            Writes the results of the experiment to the specified output directory and
                updates metadata.
    """

    experiment: Callable
    metadata: ExperimentMetadata

    def __init__(
        self,
        exp_config: ExperimentConfig,
        variant_config: VariantConfig,
        run_id: str,
    ):
        module = importlib.import_module(exp_config.module)
        cls = getattr(module, exp_config.class_name)

        # build up init_params,
        # wrapper passes the run_id and variant_name to experiment __call__ method
        init_params = variant_config.init_params or {}
        init_params["run_id"] = run_id
        init_params["variant_name"] = variant_config.name
        self.experiment = cls(**init_params)

        self.metadata = ExperimentMetadata(
            experiment_name=exp_config.name,
            variant_name=variant_config.name,
            evaluation=variant_config.evaluation,
            run_id=run_id,
        )

    def run(
        self,
        data_filename: str = "none",
        line_number: int = 0,
        **kwargs: Any,
    ) -> dict:
        """
        Runs the experiment with the provided data filename and line number.
        Args:
            data_filename (str, optional): The name of the data file.
                Defaults to "none".
            line_number (int | str, optional): The line number in the data file.
                Defaults to "none".
            **kwargs: keyword arguments to pass to the experiment's __call__ method.
        Returns:
            dict: A dictionary containing the results of the experiment. If an
                error occurs, the dictionary will contain an 'error' key with
                the error message.
        """
        line_number += 1
        attributes: dict = {
            "experiment.name": self.metadata.experiment_name,
            "experiment.variant.name": self.metadata.variant_name,
            "experiment.run_id": self.metadata.run_id,
            "data.filename": data_filename,
            "data.line_number": line_number,
        }

        run_result = {**kwargs}
        try:
            with tracer.start_as_current_span("experiment", attributes=attributes):
                logger.info(
                    f"Running experiment on data line number: {line_number}, "
                    f"experiment: '{self.metadata.fullname()}'"
                )
                result = self.experiment(**kwargs)
                if not isinstance(result, dict):
                    run_result.update(output=result)
                else:
                    run_result.update(**result)

        except Exception as e:
            logger.error(
                f"Uncaught error running experiment '{self.metadata.fullname()}' \
                on data line number {line_number}. Error: {type(e).__name__} {e}"
            )
            run_result.update(error=str(e))
        return run_result

    def write_results(
        self,
        output_dir: Path,
        results: list,
        is_eval_data: bool = False,
    ) -> None:
        """
        Writes the experiment results and metadata to a specified output directory
        Args:
            output_dir (Path): The directory where the results will be written.
            results (list): The list of results to be written.
            is_eval_data (bool, optional): Flag indicating if the results are evaluation
                data. Defaults to False.
        Returns:
            str: The path to the directory where the results were written.
        Side Effects:
            - Creates directories if they do not exist.
            - Writes results to a JSONL file.
            - Updates metadata with the relative path to the results file.
            - Writes metadata
            - Logs the paths to the results and metadata files.
        """
        # create directory structure: output_dir/exp_name/var_name/run_id
        write_dir = output_dir.joinpath(
            self.metadata.experiment_name,
            self.metadata.variant_name,
            self.metadata.run_id,
        )
        os.makedirs(write_dir, exist_ok=True)

        # write results
        results_path = write_dir.joinpath(self.metadata.exp_results_filename)
        write_jsonl_file(results_path, results)

        # update metadata exp_results_path
        results_relative_path = f"./{self.metadata.exp_results_filename}"
        self.metadata.exp_results_path = results_relative_path

        # if eval data is contained in data file,
        # update eval_data_path to path of results file
        if is_eval_data:
            self.metadata.eval_data_path = results_relative_path

        # write metadata
        metadata_path = write_dir.joinpath(self.metadata.filename)
        write_json_file(metadata_path, asdict(self.metadata))

        logger.info(f"Results written to {results_path}. Metadata written to {metadata_path}")
