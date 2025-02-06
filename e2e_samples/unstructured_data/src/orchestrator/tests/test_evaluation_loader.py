import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from orchestrator.evaluation_config import EvaluatorLoadConfig
from orchestrator.evaluation_loader import load_evaluation, load_evaluators_and_config
from orchestrator.evaluation_wrapper import EvaluationWrapper
from orchestrator.metadata import ExperimentMetadata
from orchestrator.utils import merge_dicts


class TestEvaluationLoader(unittest.TestCase):

    @patch("orchestrator.evaluation_loader.load_instance")
    def test_load_evaluators_and_config(self, mock_load_instance: MagicMock) -> None:
        module = "path.to.module"
        class_name = "ClassName"
        eval_1_config: dict = {"column_mapping": {}}
        init_args = {"arg1": "value1"}

        eval_map = {
            "eval_1": EvaluatorLoadConfig(
                module=module,
                class_name=class_name,
                evaluator_config=eval_1_config,
                init_args=init_args,
            )
        }

        evaluators, evaluator_config = load_evaluators_and_config(evaluator_map=eval_map, init_args={"arg2": "value2"})

        expected_init_args = {"arg1": "value1", "arg2": "value2"}

        self.assertIsInstance(evaluators["eval_1"], MagicMock)
        mock_load_instance.assert_called_once_with(module=module, class_name=class_name, init_args=expected_init_args)

        self.assertEqual(evaluator_config["eval_1"], eval_1_config)

    def test_load_evaluators_and_config_missing_config(self) -> None:
        eval_map = {"eval_1": None}

        with self.assertRaises(ValueError) as context:
            load_evaluators_and_config(evaluator_map=eval_map, init_args={})

        self.assertEqual(str(context.exception), "Missing evaluator load config for eval_1")

    @patch("orchestrator.evaluation_loader.load_instance")
    @patch("orchestrator.evaluation_loader.merge_dicts", side_effect=merge_dicts)
    def test_load_evaluators_and_config_merge_args(
        self, mock_merge_dicts: MagicMock, mock_load_instance: MagicMock
    ) -> None:
        module = "path.to.module"
        class_name = "ClassName"
        eval_1_config: dict = {"column_mapping": {}}
        init_args_1 = {"arg1": "value1"}
        init_args_2 = {"arg2": "value2"}

        eval_map = {
            "eval_1": EvaluatorLoadConfig(
                module=module,
                class_name=class_name,
                evaluator_config=eval_1_config,
                init_args=init_args_1,
            )
        }

        load_evaluators_and_config(evaluator_map=eval_map, init_args=init_args_2)

        mock_merge_dicts.assert_called_once_with(init_args_2, init_args_1)

    @patch("orchestrator.evaluation_loader.load_file")
    @patch("orchestrator.evaluation_loader.load_exp_config")
    @patch("orchestrator.evaluation_loader.load_variant")
    @patch("orchestrator.evaluation_loader.load_evaluators_and_config")
    def test_load_evaluation(
        self,
        mock_load_evaluators_and_config: MagicMock,
        mock_load_variant: MagicMock,
        mock_load_exp_config: MagicMock,
        mock_load_file: MagicMock,
    ) -> None:
        metadata_path = Path("/path/to/metadata.json")
        eval_run_id = "eval_run_123"
        experiments_dir = Path("/path/to/experiments")

        metadata_dict = {
            "experiment_config_path": "exp_config.json",
            "variant_config_path": "variant_config.json",
            "eval_data_path": "data.json",
            "run_id": "run_123",
        }
        metadata = ExperimentMetadata(**metadata_dict)
        mock_load_file.return_value = metadata_dict

        exp_config = MagicMock()
        exp_config.name = "experiment_name"
        exp_config.variants_dir = "variants"
        exp_config.evaluators = {}
        mock_load_exp_config.return_value = exp_config

        variant = MagicMock()
        variant.name = "variant_name"
        variant.evaluation.evaluators = {}
        variant.evaluation.init_args = {}
        variant.evaluation.tags = ["tag1", "tag2"]
        mock_load_variant.return_value = variant

        evaluators = {"evaluator_1": MagicMock()}
        evaluator_config: dict = {"evaluator_1": {}}
        mock_load_evaluators_and_config.return_value = (evaluators, evaluator_config)

        result = load_evaluation(
            metadata_path=metadata_path,
            eval_run_id=eval_run_id,
            experiments_dir=experiments_dir,
        )

        self.assertIsInstance(result, EvaluationWrapper)
        self.assertEqual(result.data_path, metadata_path.parent.joinpath(metadata.eval_data_path))
        self.assertEqual(result.experiment_name, exp_config.name)
        self.assertEqual(result.variant_name, variant.name)
        self.assertEqual(result.evaluators, evaluators)
        self.assertEqual(result.evaluator_config, evaluator_config)
        self.assertEqual(result.eval_run_id, eval_run_id)
        self.assertEqual(result.experiment_run_id, metadata.run_id)
        self.assertEqual(result.tags, variant.evaluation.tags)

        mock_load_file.assert_called_once_with(metadata_path)
        mock_load_exp_config.assert_called_once_with(experiments_dir.joinpath(metadata.experiment_config_path))
        mock_load_variant.assert_called_once_with(
            variant_path=experiments_dir.joinpath("variants", metadata.variant_config_path),
            exp_evaluators=exp_config.evaluators,
        )
        mock_load_evaluators_and_config.assert_called_once_with(
            evaluator_map=variant.evaluation.evaluators,
            init_args=variant.evaluation.init_args,
        )
