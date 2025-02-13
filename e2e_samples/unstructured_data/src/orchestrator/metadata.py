import importlib
from copy import deepcopy
from dataclasses import dataclass
from typing import Optional

from orchestrator.evaluation_config import EvaluationConfig
from orchestrator.utils import merge_dicts


@dataclass
class ExperimentMetadata:
    """
    A class to represent metadata for an experiment.
    This class is used to run evaluations on experiment results.

    Attributes:
        experiment_name: str
            The name of the experiment.
        variant_name: str
            The name of the variant.
        run_id: str
            The ID of the run.
        evaluation: Optional[EvaluationConfig]
            The evaluation configuration (default is None).
        exp_results_path: Optional[str]
            The path to the experiment results (default is None).
        eval_data_path: Optional[str]
            The path to the evaluation data (default is None).
    """

    experiment_name: str
    variant_name: str
    run_id: str
    evaluation: Optional[EvaluationConfig] = None
    exp_results_path: Optional[str] = None
    eval_data_path: Optional[str] = None

    # default filenames
    exp_results_filename = "exp_results.jsonl"
    eval_data_filename = "eval_data.jsonl"
    eval_results_filename_suffix = "_eval_results.json"
    filename = "metadata.json"

    def fullname(self) -> str:
        return f"{self.experiment_name}:{self.variant_name}"

    @classmethod
    def from_dict(cls, data: dict) -> "ExperimentMetadata":
        data_copy = deepcopy(data)
        evaluation = data.get("evaluation")
        if evaluation is not None:
            data_copy["evaluation"] = EvaluationConfig.from_dict(evaluation)
        return cls(**data_copy)

    def load_evaluators_and_config(self) -> tuple[dict, dict]:
        """
        Load evaluators and their configurations.
        This method initializes and returns evaluators and their configurations
        based on the evaluation attribute of the instance. If no evaluators are
        found in the evaluation, a ValueError is raised.
        Returns:
            tuple: A tuple containing two dictionaries:
                - evaluators (dict): A dictionary where the keys are evaluator names
                  and the values are instances of the evaluator classes.
                - config (dict): A dictionary where the keys are evaluator names
                  and the values are the corresponding evaluator configurations.
        Raises:
            ValueError: If no evaluators are found in the evaluation attribute.
        """
        evaluators = {}
        config = {}

        if self.evaluation is not None:
            if self.evaluation.evaluators is None:
                raise ValueError(
                    f"No evaluators found. experiment: {self.experiment_name}, \
                        variant: {self.variant_name}, run_id: {self.run_id}"
                )
            common_init_params = self.evaluation.init_params or {}

            for name, c in self.evaluation.evaluators.items():
                module = importlib.import_module(c.module)
                cls = getattr(module, c.class_name)
                init_params = c.init_params or {}
                # merge common init params
                # evaluator speficic init_params take precedence
                init_params = merge_dicts(common_init_params, init_params)
                evaluators[name] = cls(**init_params)

                if c.evaluator_config is not None:
                    config[name] = c.evaluator_config

        return evaluators, config
