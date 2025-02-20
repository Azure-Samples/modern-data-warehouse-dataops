from pathlib import Path

from orchestrator.config import Config
from orchestrator.experiment_config import load_exp_config
from orchestrator.experiment_wrapper import ExperimentWrapper
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import load_instance
from orchestrator.variant_config import load_variant


def load_experiments(
    config_filepath: str,
    variants: list[str],
    run_id: str,
) -> list[ExperimentWrapper]:
    """
    Load and initialize experiments based on the provided configuration
    file and variants.
    Args:
        config_filepath (str): Path to the experiment configuration file.
        variants (list[str]): List of variant file paths to load.
        run_id (str): Unique identifier for the experiment run.
        experiments_dir (str, optional): Directory where experiment configurations are stored.
    Returns:
        list[ExperimentWrapper]: A list of initialized ExperimentWrapper objects.
    """
    exp_config_fullpath = Config.experiments_dir.joinpath(config_filepath)
    exp_config = load_exp_config(exp_config_fullpath)

    variants_dir = exp_config_fullpath.parent.joinpath(exp_config.variants_dir)
    unique_variants: dict[str, Path] = {}
    wrappers: list[ExperimentWrapper] = []
    for v_path in variants:
        v_fullpath = variants_dir.joinpath(v_path)
        variant = load_variant(
            variant_path=v_fullpath,
            exp_evaluators=exp_config.evaluators,
        )

        # ensure variant has a name
        if variant.name is None:
            raise ValueError(f"Variant must have a name: {v_fullpath}")

        if variant.version is None:
            raise ValueError(f"Variant must have a version: {v_fullpath}")

        name_version = f"{variant.name}:{variant.version}"

        # ensure name and version are unique for the run
        existing = unique_variants.get(name_version)
        if existing is not None:
            raise ValueError(
                f"Variant names must be unqiue for experiment runs. Found duplicate name: {variant.name} at paths:"
                f" [{v_fullpath}, {existing}]"
            )
        unique_variants[name_version] = v_fullpath

        # set path
        variant.path = v_path
        # add run_id and variant name to init_args
        variant.init_args["run_id"] = variant.init_args.get("run_id", run_id)
        variant.init_args["variant_name"] = variant.init_args.get("variant_name", variant.name)

        # create metadata
        metadata = ExperimentMetadata(
            experiment_config_path=config_filepath,
            variant_config_path=variant.path,
            run_id=run_id,
        )

        # load experiment
        experiment = load_instance(
            module=exp_config.module,
            class_name=exp_config.class_name,
            init_args=variant.init_args,
        )

        wrappers.append(
            ExperimentWrapper(
                experiment=experiment,
                experiment_name=exp_config.name,
                variant_name=variant.name,
                variant_version=variant.version,
                metadata=metadata,
                output_container=variant.output_container or variant.default_output_container,
                additional_call_args=variant.call_args,
            )
        )

    return wrappers
