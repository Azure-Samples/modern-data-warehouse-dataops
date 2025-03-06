from copy import deepcopy
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional

from orchestrator.evaluation_config import EvaluationConfig, EvaluatorLoadConfigMap, merge_eval_config_maps
from orchestrator.file_utils import load_file
from orchestrator.utils import merge_dicts


@dataclass
class VariantConfig:
    """
    VariantConfig is a configuration class for defining experiment variants.
    Attributes:
        name (Optional[str]): The name of the variant.
        parent_variants (list[str]): A list of parent variant names.
        init_args (dict): A dictionary of initialization arguments.
        call_args (dict): A dictionary of arguments for the experiment  __call__ method.
        evaluation (EvaluationConfig): The evaluation configuration for the variant.
        path (Optional[str]): The file path associated with the variant.
        output_container (Optional[str]): The output container for the variant.
        default_output_container (str): The default output container, set to ".".
    """

    version: Optional[str] = None
    name: Optional[str] = None
    parent_variants: list[str] = field(default_factory=list)
    init_args: dict = field(default_factory=dict)
    call_args: dict = field(default_factory=dict)
    evaluation: EvaluationConfig = field(default_factory=EvaluationConfig)
    path: Optional[str] = None
    output_container: Optional[str] = None
    default_output_container = "."


def merge_variant_configs(vc1: VariantConfig, vc2: VariantConfig) -> VariantConfig:
    """
    Merges two VariantConfig objects into one.
    Args:
        vc1 (VariantConfig): The first variant configuration.
        vc2 (VariantConfig): The second variant configuration.
    Returns:
        VariantConfig: A new VariantConfig object that is a combination of vc1 and vc2.
    """
    merged = deepcopy(vc2)
    if merged.name is None and vc1.name is not None:
        merged.name = vc1.name

    if merged.version is None and vc1.version is not None:
        merged.version = vc1.version

    if merged.output_container is None and vc1.output_container is not None:
        merged.output_container = vc1.output_container

    if not merged.parent_variants and vc1.parent_variants:
        merged.parent_variants = vc1.parent_variants

    # merge init_args
    merged.init_args = merge_dicts(vc1.init_args, merged.init_args)
    # merge call_args
    merged.call_args = merge_dicts(vc1.call_args, merged.call_args)
    # merge evaluation
    merged_eval = merge_dicts(asdict(vc1.evaluation), asdict(merged.evaluation))
    merged.evaluation = EvaluationConfig(**merged_eval)
    return merged


def load_variant(
    variant_path: Path,
    exp_evaluators: Optional[EvaluatorLoadConfigMap] = None,
) -> VariantConfig:
    """
    Load and merge variant configurations from the specified file path.
    This function loads a variant configuration from a YAML file, merges additional
    configurations if specified, merges evaluator configurations, and recursively
    loads and merges parent variant configurations.
    Args:
        variant_filepath (Path): The path to the variant file to load.
        exp_evaluators (Optional[EvaluatorLoadConfigMap]): The evaluator configs to merge.
    Returns:
        VariantConfig: The loaded and merged variant configuration.
    """

    def load(path: Path, check_has_name: bool = False) -> VariantConfig:
        data = load_file(path)
        if not isinstance(data, dict):
            raise ValueError(f"Invalid variant configuration in {variant_path}")

        evaluation_data = data.get("evaluation", {})
        data["evaluation"] = EvaluationConfig(**evaluation_data)
        variant = VariantConfig(**data)

        # merge evaluators from experiment config
        if exp_evaluators is not None and variant.evaluation is not None:
            variant.evaluation.evaluators = merge_eval_config_maps(exp_evaluators, variant.evaluation.evaluators)

        # merge parent variants
        if variant.parent_variants:
            for p in variant.parent_variants:
                config_path = path.parent.joinpath(p)
                additional_config = load(config_path)
                variant = merge_variant_configs(additional_config, variant)

        return variant

    return load(variant_path, check_has_name=True)
