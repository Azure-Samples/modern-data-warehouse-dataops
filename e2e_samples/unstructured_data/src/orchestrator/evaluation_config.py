from copy import deepcopy
from dataclasses import asdict, dataclass
from typing import Dict, Optional, TypedDict

from orchestrator.utils import merge_dicts


class EvaluatorConfig(TypedDict, total=False):
    """Configuration for an evaluator"""

    column_mapping: Dict[str, str]
    """Dictionary mapping evaluator input name to column in data"""


@dataclass
class EvaluatorLoadConfig:
    """
    EvaluatorLoadConfig is a configuration class for loading an evaluator.

    Attributes:
        module (str): The module where the evaluator class is located.
        class_name (str): The name of the evaluator class to be instantiated.
        evaluator_config (Optional[dict]): Optional configuration dictionary for the
            evaluator.
        init_params (Optional[dict]): Optional initialization parameters for the
            evaluator.
    """

    module: str
    class_name: str
    evaluator_config: Optional[dict[str, EvaluatorConfig]] = None
    init_params: Optional[dict] = None


EvaluatorLoadConfigMap = Dict[str, EvaluatorLoadConfig]


@dataclass
class EvaluationConfig:
    """
    EvaluationConfig class to hold configuration for evaluation.
    Attributes:
        init_params (Optional[dict]): Initialization parameters for the evaluation.
        evaluators (Optional[EvaluatorConfigMap]): A mapping of evaluator names to
            their configurations.
        tags (Optional[dict]): Additional tags for the evaluation configuration.
    Methods:
        from_dict(cls, data: dict):
            Creates an instance of EvaluationConfig from a dictionary.
            Args:
                data (dict): A dictionary containing the configuration data.
            Returns:
                EvaluationConfig: An instance of EvaluationConfig populated with
                    the provided data.
    """

    init_params: Optional[dict] = None
    evaluators: Optional[EvaluatorLoadConfigMap] = None
    tags: Optional[dict] = None

    @classmethod
    def from_dict(cls, data: dict) -> "EvaluationConfig":
        data_copy = deepcopy(data)
        evaluators = data.get("evaluators")
        if isinstance(evaluators, dict):
            evaluators = {name: EvaluatorLoadConfig(**config) for name, config in evaluators.items()}
        data_copy["evaluators"] = evaluators

        return cls(**data_copy)


def merge_eval_config_maps(
    exp_evaluators: EvaluatorLoadConfigMap,
    variant_evaluators: Optional[EvaluatorLoadConfigMap] = None,
) -> Optional[Dict[str, EvaluatorLoadConfig]]:
    """
    Merges two evaluator configuration maps.
    This function takes two evaluator configuration maps, `exp_evaluators` and
    `variant_evaluators`, and merges them. If `variant_evaluators` is None, the
    function returns None. Otherwise, it combines the configurations from both
    maps. If a configuration exists in both maps, the configurations are merged
    using the `merge_dicts` function. If a configuration exists in only one map,
    that configuration is used.
    Args:
        exp_evaluators (EvaluatorConfigMap): The experiment evaluator config map.
        variant_evaluators (Optional[EvaluatorConfigMap]): The variant evaluator
            config map to merge with the experiment config map. Defaults to None.
    Returns:
        Optional[Dict[str, EvaluatorLoadConfig]]: A dictionary containing the merged
        evaluator configurations, or None if `variant_evaluators` is None.
    """
    if variant_evaluators is None:
        return None

    merged = {}
    for name, variant_eval_config in variant_evaluators.items():
        exp_eval_config = exp_evaluators.get(name)
        if exp_eval_config is None:
            merged[name] = variant_eval_config
        elif variant_eval_config is None:
            merged[name] = exp_eval_config
        else:
            merged_config = merge_dicts(asdict(exp_eval_config), asdict(variant_eval_config))
            merged[name] = EvaluatorLoadConfig(**merged_config)

    return merged
