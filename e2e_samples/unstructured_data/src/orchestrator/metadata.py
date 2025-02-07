from dataclasses import dataclass
from typing import Optional


@dataclass
class ExperimentMetadata:
    """
    A class to represent metadata for an experiment.
    This class is used to run evaluations on experiment results.

    Attributes:
        experiment_name (str): The name of the experiment.
        variant_name (str): The name of the variant.
        run_id (str): The ID of the run.
        exp_results_path (Optional[str]): The path to the experiment results (default is None).
        eval_data_path (Optional[str]): The path to the evaluation data (default is None).
    """

    run_id: str
    experiment_config_path: str
    variant_config_path: str
    exp_results_path: Optional[str] = None
    eval_data_path: Optional[str] = None

    # default filenames
    exp_results_filename = "exp_results.jsonl"
    eval_data_filename = "eval_data.jsonl"
    eval_results_filename_suffix = "_eval_results.json"
    filename = "metadata.json"
