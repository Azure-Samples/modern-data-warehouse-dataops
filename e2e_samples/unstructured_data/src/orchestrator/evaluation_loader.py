from pathlib import Path

from orchestrator.config import Config
from orchestrator.evaluation_config import EvaluatorLoadConfigMap
from orchestrator.evaluation_wrapper import EvaluationWrapper
from orchestrator.experiment_config import load_exp_config
from orchestrator.file_utils import load_file
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import load_instance, merge_dicts
from orchestrator.variant_config import load_variant


def load_evaluators_and_config(evaluator_map: EvaluatorLoadConfigMap, init_args: dict) -> tuple[dict, dict]:
    evaluators = {}
    evaluator_config = {}
    for name, c in evaluator_map.items():
        if c is None:
            raise ValueError(f"Missing evaluator load config for {name}")

        if c.module is None or c.class_name is None:
            raise ValueError(f"Missing module or class name for evaluator {name}")

        init_args = merge_dicts(init_args, c.init_args)

        evaluators[name] = load_instance(module=c.module, class_name=c.class_name, init_args=init_args)

        evaluator_config[name] = c.evaluator_config

    return evaluators, evaluator_config


def load_evaluation(
    metadata_path: Path,
    eval_run_id: str,
    experiments_dir: Path = Config.experiments_dir,
) -> EvaluationWrapper:
    metadata_dict = load_file(metadata_path)
    if not isinstance(metadata_dict, dict):
        raise ValueError(f"Invalid metadata in {metadata_path}")
    metadata = ExperimentMetadata(**metadata_dict)

    exp_config_fullpath = experiments_dir.joinpath(metadata.experiment_config_path)
    exp_config = load_exp_config(exp_config_fullpath)

    variant_path = exp_config_fullpath.parent.joinpath(exp_config.variants_dir, metadata.variant_config_path)
    variant = load_variant(
        variant_path=variant_path,
        exp_evaluators=exp_config.evaluators,
    )

    evaluators, evaluator_config = load_evaluators_and_config(
        evaluator_map=variant.evaluation.evaluators,
        init_args=variant.evaluation.init_args,
    )

    if variant.name is None or variant.version is None:
        raise ValueError(f"Variant must have a name and version: {variant_path}")

    if metadata.eval_data_path is None:
        raise ValueError(f"Missing eval_data_path in metadata: {metadata_path}")

    return EvaluationWrapper(
        data_path=str(metadata_path.parent.joinpath(metadata.eval_data_path)),
        experiment_name=exp_config.name,
        variant_name=variant.name,
        version=variant.version,
        evaluators=evaluators,
        evaluator_config=evaluator_config,
        eval_run_id=eval_run_id,
        experiment_run_id=metadata.run_id,
        tags=variant.evaluation.tags,
    )
