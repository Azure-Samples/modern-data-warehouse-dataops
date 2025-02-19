import os
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Callable, Optional

from opentelemetry import trace
from orchestrator.config import Config
from orchestrator.file_utils import write_json_file, write_jsonl_file
from orchestrator.logging import get_logger
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import flatten_dict

logger = get_logger(__name__)

tracer = trace.get_tracer(__name__)


@dataclass
class ExperimentWrapper:
    """
    ExperimentWrapper is a class that wraps around an experiment,
        providing methods to run the experiment and write the results to a
        specified output directory.
    Attributes:
        experiment (Callable): The experiment instance to be run.
        metadata (ExperimentMetadata): Metadata associated with the experiment.
        output_container (str): The container for the experiment output.
        additional_call_args (dict): Additional keyword arguments to pass to the experiment __call__ method.
    """

    experiment: Callable
    experiment_name: str
    variant_name: str
    metadata: ExperimentMetadata
    output_container: str
    additional_call_args: dict = field(default_factory=dict)

    def run(
        self,
        data_filename: str = "none",
        line_number: int = 0,
        call_args: Optional[dict] = None,
    ) -> dict:
        """
        Runs the experiment with the provided data filename and line number.
        Args:
            data_filename (str, optional): The name of the data file. Defaults to "none".
            line_number (int, optional): The line number in the data file. Defaults to 0.
            call_kwargs: keyword arguments to pass to the experiment's __call__ method.
        Returns:
            dict: A dictionary containing the results of the experiment. If an error occurs,
                the dictionary will contain an 'error' key with the error message.
        """
        attributes = {
            "experiment.name": self.experiment_name,
            "experiment.variant.name": self.variant_name,
            "experiment.run_id": self.metadata.run_id,
            "data.filename": data_filename,
            "data.line_number": str(line_number),
        }

        exp_fullname = f"{self.experiment_name}:{self.variant_name}"

        if call_args is None:
            call_args = {}
        inputs = {**self.additional_call_args, **call_args}
        output = flatten_dict({"inputs": inputs})
        try:
            with tracer.start_as_current_span("experiment", attributes=attributes):
                logger.info(f"Running experiment on data line number: {line_number}, " f"experiment: '{exp_fullname}'")
                result = self.experiment(**inputs)

                if not isinstance(result, dict):
                    result = {"output": result}

                flattened_result = flatten_dict(result)
                output.update(flattened_result)

        except Exception as e:
            logger.error(
                f"Uncaught error running experiment '{exp_fullname}' \
                on data line number {line_number}. Error: {type(e).__name__} {e}"
            )
            output.update(error=str(e))
        return output

    def write_results(
        self,
        results: list,
        is_eval_data: bool = False,
        output_dir: Path = Config.run_outputs_dir,
    ) -> None:
        """
        Writes the experiment results and metadata to a specified output directory
        Args:
            results (list): The list of results to be written.
            is_eval_data (bool, optional): Flag indicating if the results are evaluation
                data. Defaults to False.
            output_dir (Path): The directory where the results will be written.
        Returns:
            str: The path to the directory where the results were written.
        Side Effects:
            - Creates directories if they do not exist.
            - Writes results to a JSONL file.
            - Updates metadata with the relative path to the results file.
            - Writes metadata
            - Logs the paths to the results and metadata files.
        """
        # create directory structure:
        # output_dir/exp_name/output_container/var_name/run_id
        write_dir = output_dir.joinpath(
            self.experiment_name,
            self.output_container,
            self.variant_name,
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
        metadata_dict = asdict(self.metadata)
        write_json_file(metadata_path, metadata_dict)

        logger.info(f"Results written to {results_path}. Metadata written to {metadata_path}")
