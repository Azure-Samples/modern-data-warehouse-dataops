from copy import deepcopy
from dataclasses import asdict, dataclass
from typing import Optional

from orchestrator.evaluation_config import EvaluationConfig, EvaluatorLoadConfig
from orchestrator.utils import merge_dicts


@dataclass
class VariantConfig:
    """
    A configuration class for a variant for an experiment.
    Attributes:
        name (str): The name of the variant.
        additional_config_path (Optional[str]): Path to additional configuration file.
        parent_variants (Optional[list[str]]): List of parent variant names.
        init_params (Optional[dict]): Initialization parameters for the variant.
        evaluation (Optional[EvaluationConfig]): Evaluation configuration for the
            variant.
    Methods:
        from_dict(cls, data: dict):
            Creates an instance of VariantConfig from a dictionary.
            Args:
                data (dict): A dictionary containing the configuration data.
            Returns:
                VariantConfig: An instance of VariantConfig.
    """

    name: str
    additional_config_path: Optional[str] = None
    parent_variants: Optional[list[str]] = None
    init_params: Optional[dict] = None
    evaluation: Optional[EvaluationConfig] = None

    @classmethod
    def from_dict(cls, data: dict) -> "VariantConfig":
        evaluation = data.get("evaluation")
        if evaluation is not None:
            evaluation = EvaluationConfig(**evaluation)

        return cls(
            name=data["name"],
            parent_variants=data.get("parent_variants"),
            additional_config_path=data.get("additional_config_path"),
            init_params=data.get("init_params"),
            evaluation=evaluation,
        )


def merge_variant_configs(vc1: VariantConfig, vc2: VariantConfig) -> VariantConfig:
    """
    Merges two VariantConfig objects into one.
    Args:
        vc1 (VariantConfig): The first variant configuration.
        vc2 (VariantConfig): The second variant configuration.
    Returns:
        VariantConfig: A new VariantConfig object that is a combination of vc1 and vc2.
    The merging process includes:
        - Combining the names of vc1 and vc2.
        - Using the additional_config_path from vc2 if it exists, otherwise keeping
            the one from vc1.
        - Merging the parent_variants lists from both configurations.
        - Merging the init_params dictionaries from both configurations.
        - Merging the evaluation configurations from both configurations.
    """
    merged = deepcopy(vc1)
    # combine name
    merged.name = f"{merged.name}_{vc2.name}"

    # use additional_config
    merged.additional_config_path = vc2.additional_config_path or merged.additional_config_path

    # merge parent variants from vc2 if it exists, otherwise keeping the one from vc1
    vc2_parent_variants = [] if vc2.parent_variants is None else vc2.parent_variants
    if merged.parent_variants is None:
        merged.parent_variants = vc2_parent_variants
    else:
        merged.parent_variants.extend(vc2_parent_variants)

    # merge init_params, vc2 takes precedence
    if vc2.init_params is not None:
        if merged.init_params is not None:
            merged.init_params = merge_dicts(merged.init_params, vc2.init_params)
        else:
            merged.init_params = vc2.init_params

    # merge evaluation, vc2 takes precedence
    if vc2.evaluation is not None:
        if merged.evaluation is not None:
            merged_eval = merge_dicts(asdict(merged.evaluation), asdict(vc2.evaluation))
        else:
            merged_eval = asdict(vc2.evaluation)
        merged.evaluation = EvaluationConfig(**merged_eval)

    return merged


@dataclass
class ExperimentConfig:
    """
    ExperimentConfig class to hold configuration details for an experiment.
    Attributes:
        name (str): The name of the experiment.
        module (str): The module where the experiment class is located.
        class_name (str): The name of the experiment class.
        evaluators (Optional[dict[str, EvaluatorLoadConfig]]): A dictionary of evaluator
            configurations, default is None.
        variants_dir (str): The realative directory where variant configurations are
            stored, default is "./variants".
    Methods:
        from_dict(cls, data: dict): Class method to create an instance of
            ExperimentConfig from a dictionary.
            Args:
                data (dict): A dictionary containing the configuration data.
            Returns:
                ExperimentConfig: An instance of ExperimentConfig.
    """

    name: str
    module: str
    class_name: str
    evaluators: Optional[dict[str, EvaluatorLoadConfig]] = None
    variants_dir: str = "./variants"

    @classmethod
    def from_dict(cls, data: dict) -> "ExperimentConfig":
        data_evaluators = data.get("evaluators")

        evaluators = None
        if isinstance(data_evaluators, dict):
            evaluators = {}
            for k, v in data_evaluators.items():
                evaluators[k] = EvaluatorLoadConfig(**v)

        return cls(
            name=data["name"],
            module=data["module"],
            class_name=data["class_name"],
            evaluators=evaluators,
        )
