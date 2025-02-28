from dataclasses import dataclass, field
from pathlib import Path

from orchestrator.evaluation_config import EvaluatorLoadConfigMap
from orchestrator.file_utils import load_file


@dataclass
class ExperimentConfig:
    """
    ExperimentConfig class to hold configuration details for an experiment.
    Attributes:
        name (str): The name of the experiment.
        module (str): The module where the experiment class is located.
        class_name (str): The name of the experiment class.
        evaluators (dict[str, EvaluatorLoadConfig]): A dictionary of evaluator
            configurations, default is None.
        variants_dir (str): The realative directory where variant configurations are
            stored, default is "./variants".
    """

    name: str
    module: str
    class_name: str
    evaluators: EvaluatorLoadConfigMap = field(default_factory=dict)
    variants_dir: str = "./variants"


def load_exp_config(path: Path) -> ExperimentConfig:
    exp_config_data = load_file(path)
    if not isinstance(exp_config_data, dict):
        raise ValueError(f"Invalid experiment configuration in {path}")
    return ExperimentConfig(**exp_config_data)
