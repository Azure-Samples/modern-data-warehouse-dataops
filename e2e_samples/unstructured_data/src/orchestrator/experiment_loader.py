from pathlib import Path

from orchestrator.experiment_config import VariantConfig, load_exp_config, load_variant
from orchestrator.experiment_wrapper import ExperimentWrapper
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import load_instance


def load_experiments(
    config_filepath: str,
    variants: list[str],
    run_id: str,
    experiments_dir: Path,
) -> list[ExperimentWrapper]:
    """
    Load and initialize experiments based on the provided configuration
    file and variants.
    Args:
        config_filepath (str): Path to the experiment configuration file.
        variants (list[str]): List of variant file paths to load.
        run_id (str): Unique identifier for the experiment run.
        experiments_dir (str, optional): Directory where experiment
            configurations are stored. Defaults to Config.experiments_dir.
    Returns:
        list[ExperimentWrapper]: A list of initialized ExperimentWrapper objects.
    """
    exp_config_fullpath = experiments_dir.joinpath(config_filepath)
    exp_config = load_exp_config(exp_config_fullpath)

    variants_dir = exp_config_fullpath.parent.joinpath(exp_config.variants_dir)
    variant_configs: list[VariantConfig] = []
    unique_variants: dict[str, Path] = {}
    for v_path in variants:
        v_fullpath = variants_dir.joinpath(v_path)
        variant = load_variant(
            variant_path=v_fullpath,
            exp_evaluators=exp_config.evaluators,
        )
        variant.path = v_path

        # ensure names are unique for the run
        if variant.name is None:
            raise ValueError(f"Variant must have a name: {v_fullpath}")
        existing = unique_variants.get(variant.name)
        if existing is not None:
            raise ValueError(
                "Variant names must be unqiue for experiment runs. "
                f"Found duplicate name: {variant.name} at paths "
                f"[{v_fullpath}, "
                f"{existing}]"
            )
        unique_variants[variant.name] = v_fullpath

        variant_configs.append(variant)

    wrappers: list[ExperimentWrapper] = []
    for vc in variant_configs:
        if vc.path is None:
            raise ValueError("Variant must have a path")

        metadata = ExperimentMetadata(
            experiment_config_path=config_filepath,
            variant_config_path=vc.path,
            run_id=run_id,
        )
        vc.init_args["run_id"] = vc.init_args.get("run_id", run_id)
        vc.init_args["variant_name"] = vc.init_args.get("variant_name", vc.name)

        experiment = load_instance(
            module=exp_config.module,
            class_name=exp_config.class_name,
            init_args=vc.init_args,
        )

        wrappers.append(
            ExperimentWrapper(
                experiment=experiment,
                experiment_name=exp_config.name,
                variant_name=vc.name,
                metadata=metadata,
                output_container=vc.output_container or vc.default_output_container,
                additional_call_args=vc.call_args,
            )
        )
    return wrappers
