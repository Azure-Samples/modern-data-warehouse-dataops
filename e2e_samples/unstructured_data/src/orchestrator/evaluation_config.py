from dataclasses import asdict, dataclass, field, is_dataclass
from typing import Optional, TypedDict

from orchestrator.types import NotGiven
from orchestrator.utils import merge_dicts


class EvaluatorConfig(TypedDict, total=False):
    """Configuration for an evaluator"""

    column_mapping: dict[str, str]
    """Dictionary mapping evaluator input name to column in data"""


@dataclass
class EvaluatorLoadConfig:
    """
    Configuration class for loading an evaluator.
    Attributes:
        module (str): The module where the evaluator class is located.
        class_name (str): The name of the evaluator class.
        evaluator_config (dict[str, EvaluatorConfig]): A dictionary containing evaluator configurations
        init_args (dict): A dictionary containing initialization arguments for the evaluator.
    """

    module: Optional[str | NotGiven] = field(default_factory=NotGiven)
    class_name: Optional[str | NotGiven] = field(default_factory=NotGiven)
    evaluator_config: EvaluatorConfig | dict = field(default_factory=dict)
    init_args: dict = field(default_factory=dict)


EvaluatorLoadConfigMap = dict[str, EvaluatorLoadConfig | None]


@dataclass
class EvaluationConfig:
    """
    Configuration class for evaluation settings.
    Attributes:
        init_args (dict): Initialization arguments for the evaluation.
        evaluators (EvaluatorConfigMap): A mapping of evaluator names to their configs.
        tags (dict): Additional tags for the evaluation configuration.
    Args:
        init_args (dict, optional): Initialization arguments for the evaluation.
        evaluators (dict, optional): A dictionary of evaluator configurations.
        tags (dict, optional): Additional tags for the evaluation configuration.
    """

    init_args: dict = field(default_factory=dict)
    evaluators: EvaluatorLoadConfigMap = field(default_factory=EvaluatorLoadConfigMap)
    tags: dict = field(default_factory=dict)

    def __init__(
        self,
        init_args: Optional[dict] = None,
        evaluators: Optional[dict] = None,
        tags: Optional[dict] = None,
    ):
        self.init_args = init_args or {}
        self.tags = tags or {}

        self.evaluators = evaluators or {}
        for name, config in self.evaluators.items():
            if isinstance(config, dict):
                self.evaluators[name] = EvaluatorLoadConfig(**config)


def merge_eval_config_maps(
    exp_evaluators: EvaluatorLoadConfigMap,
    variant_evaluators: EvaluatorLoadConfigMap,
) -> EvaluatorLoadConfigMap:
    """
    Merges two evaluator configuration maps into a single map.
    Args:
        exp_evaluators (EvaluatorLoadConfigMap): The evaluator configuration map from the experiment config.
        variant_evaluators (EvaluatorLoadConfigMap): The evaluator configuration map from the variant config.
    Returns:
        EvaluatorLoadConfigMap: A dictionary containing the merged evaluator configurations. If a configuration, exists
            in both maps, the variant configuration will take precedence.
    """

    merged = {}
    for name, variant_eval_config in variant_evaluators.items():
        exp_eval_config = exp_evaluators.get(name)
        if exp_eval_config is None:
            merged[name] = variant_eval_config
        elif variant_eval_config is None:
            merged[name] = exp_eval_config
        else:
            if is_dataclass(exp_eval_config):
                exp_eval_config_dict = asdict(exp_eval_config)
            else:
                exp_eval_config_dict = exp_eval_config
            merged_config = merge_dicts(exp_eval_config_dict, asdict(variant_eval_config))
            merged[name] = EvaluatorLoadConfig(**merged_config)

    return merged
