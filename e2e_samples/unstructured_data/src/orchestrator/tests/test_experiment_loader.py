import unittest
from unittest.mock import MagicMock, patch

from orchestrator.experiment_loader import load_experiments
from orchestrator.experiment_wrapper import ExperimentWrapper


class TestLoadExperiments(unittest.TestCase):

    @patch("orchestrator.experiment_loader.load_exp_config")
    @patch("orchestrator.experiment_loader.load_variant")
    @patch("orchestrator.experiment_loader.load_instance")
    def test_load_experiments(
        self, mock_load_instance: MagicMock, mock_load_variant: MagicMock, mock_load_exp_config: MagicMock
    ) -> None:
        # Mocking the configuration and variant loading
        mock_exp_config = MagicMock()
        mock_exp_config.variants_dir = "variants"
        mock_exp_config.evaluators = []
        mock_exp_config.module = "test_module"
        mock_exp_config.class_name = "TestClass"
        mock_exp_config.name = "TestExperiment"
        mock_load_exp_config.return_value = mock_exp_config

        mock_variant = MagicMock()
        mock_variant.name = "variant1"
        mock_variant.init_args = {}
        mock_variant.output_container = None
        mock_variant.default_output_container = "default_container"
        mock_load_variant.return_value = mock_variant

        mock_instance = MagicMock()
        mock_load_instance.return_value = mock_instance

        config_filepath = "config.yaml"
        variants = ["variant1.yaml"]
        run_id = "test_run_id"
        experiments_dir = MagicMock()
        experiments_dir.joinpath.return_value = experiments_dir

        # Call the function
        result = load_experiments(config_filepath, variants, run_id, experiments_dir)

        # Assertions
        self.assertEqual(len(result), 1)
        self.assertIsInstance(result[0], ExperimentWrapper)
        self.assertEqual(result[0].experiment, mock_instance)
        self.assertEqual(result[0].experiment_name, "TestExperiment")
        self.assertEqual(result[0].variant_name, "variant1")
        self.assertEqual(result[0].metadata.run_id, run_id)
        self.assertEqual(result[0].output_container, "default_container")

    @patch("orchestrator.experiment_loader.load_exp_config")
    @patch("orchestrator.experiment_loader.load_variant")
    def test_load_experiments_duplicate_variant_names(
        self, mock_load_variant: MagicMock, mock_load_exp_config: MagicMock
    ) -> None:
        # Mocking the configuration and variant loading
        mock_exp_config = MagicMock()
        mock_exp_config.variants_dir = "variants"
        mock_exp_config.evaluators = []
        mock_load_exp_config.return_value = mock_exp_config

        mock_variant = MagicMock()
        mock_variant.name = "duplicate_variant"
        mock_variant.init_args = {}
        mock_load_variant.return_value = mock_variant

        config_filepath = "config.yaml"
        variants = ["variant1.yaml", "variant2.yaml"]
        run_id = "test_run_id"
        experiments_dir = MagicMock()
        experiments_dir.joinpath.return_value = experiments_dir

        # Call the function and assert it raises a ValueError
        with self.assertRaises(ValueError) as context:
            load_experiments(config_filepath, variants, run_id, experiments_dir)

        self.assertIn("Variant names must be unqiue for experiment runs.", str(context.exception))
