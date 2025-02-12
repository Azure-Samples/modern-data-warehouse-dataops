from pathlib import Path
from typing import Optional

from orchestrator.evaluation_config import EvaluatorLoadConfigMap, merge_eval_config_maps
from orchestrator.experiment_config import ExperimentConfig, VariantConfig, merge_variant_configs
from orchestrator.experiment_wrapper import ExperimentWrapper
from orchestrator.file_utils import load_file, load_yaml_file


def load_variants(
    variant_filepath: Path, exp_evaluators: Optional[EvaluatorLoadConfigMap] = None
) -> list[VariantConfig]:
    """
    Load and merge variant configurations from the specified file path.
    This function loads a variant configuration from a YAML file, merges additional
    configurations if specified, merges evaluator configurations, and recursively
    loads and merges parent variant configurations.
    Args:
        variant_filepath (Path): The path to the variant file to load.
        exp_evaluators (EvaluatorConfigMap): The evaluator configurations to merge.
    Returns:
        list[VariantConfig]: A list of merged variant configurations.
    """

    def load(path: Path) -> list[VariantConfig]:
        data: dict = load_yaml_file(path)
        variant = VariantConfig.from_dict(data)

        # merge additional config
        if variant.additional_config_path is not None:
            config = load_yaml_file(path.parent.joinpath(variant.additional_config_path))
            variant = merge_variant_configs(VariantConfig.from_dict(config), variant)
            variant.additional_config_path = None

        # merge evaluators
        if variant.evaluation is not None:
            if exp_evaluators is not None:
                variant.evaluation.evaluators = merge_eval_config_maps(exp_evaluators, variant.evaluation.evaluators)

        # load and merge parent variants
        variants: list[VariantConfig] = []
        if variant.parent_variants:
            for pv_path in variant.parent_variants:
                parent_variants = load(path.parent.joinpath(pv_path))

                for pv in parent_variants:
                    merged = merge_variant_configs(pv, variant)
                    merged.parent_variants = None

                    variants.append(merged)
        # if parent_variants is not provided, append the variant
        else:
            variants.append(variant)

        return variants

    return load(variant_filepath)


def load_experiments(
    config_filepath: Path | str,
    variants: list[str],
    run_id: str,
) -> list[ExperimentWrapper]:
    """
    Load and prepare experiments based on the provided configuration file and variants.

    Args:
        config_filepath (Path | str): The path to the experiment configuration file.
        variants (list[str]): A list of variant file paths to load. The paths are
            relative to the variants directory.
        run_id (Optional[str]): An optional run identifier. If not provided, new run ID
            will be generated.
    Returns:
        list[ExperimentWrapper]: A list of ExperimentWrapper objects representing the
            loaded experiments.
    """

    if isinstance(config_filepath, str):
        config_filepath = Path(config_filepath)

    exp_config_data = load_file(config_filepath)
    if not isinstance(exp_config_data, dict):
        raise TypeError("Expected load_file to return a dictionary")
    exp_config = ExperimentConfig.from_dict(exp_config_data)

    variants_dir = config_filepath.parent.joinpath(exp_config.variants_dir)
    variant_configs: list[VariantConfig] = []
    for v in variants:
        loaded_variants = load_variants(
            variant_filepath=variants_dir.joinpath(v),
            exp_evaluators=exp_config.evaluators,
        )
        variant_configs.extend(loaded_variants)

    experiments: list[ExperimentWrapper] = []
    for vc in variant_configs:
        experiments.append(
            ExperimentWrapper(
                exp_config=exp_config,
                variant_config=vc,
                run_id=run_id,
            )
        )
    return experiments
