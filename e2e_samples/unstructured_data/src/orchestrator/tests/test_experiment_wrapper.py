import unittest
from unittest.mock import MagicMock, Mock, patch

from orchestrator.experiment_wrapper import ExperimentWrapper
from orchestrator.metadata import ExperimentMetadata


class TestExperimentWrapper(unittest.TestCase):

    def setUp(self) -> None:
        self.mock_experiment = Mock()
        self.metadata = ExperimentMetadata(
            run_id="test_run_id",
            experiment_config_path="experiment.yaml",
            variant_config_path="vc1.yaml",
            exp_results_path="results.json",
            eval_data_path="eval-results.json",
        )
        self.wrapper = ExperimentWrapper(
            experiment=self.mock_experiment,
            experiment_name="test_experiment",
            variant_name="test_variant",
            metadata=self.metadata,
            output_container="test_container",
            additional_call_args={"additional_arg": "value"},
        )

    @patch("orchestrator.experiment_wrapper.tracer")
    def test_run_success(self, mock_tracer: MagicMock) -> None:
        self.mock_experiment.return_value = {"result": "success"}
        result = self.wrapper.run(data_filename="test_data.jsonl", line_number=5, call_args={"param1": "value1"})

        self.assertEqual(result["result"], "success")
        self.mock_experiment.assert_called_once_with(param1="value1", additional_arg="value")
        mock_tracer.start_as_current_span.assert_called_once()

    @patch("orchestrator.experiment_wrapper.tracer")
    def test_run_non_dict_result(self, mock_tracer: MagicMock) -> None:
        self.mock_experiment.return_value = "success"
        result = self.wrapper.run(data_filename="test_data.jsonl", line_number=5, call_args={"param1": "value1"})

        self.assertEqual(result["output"], "success")
        self.mock_experiment.assert_called_once_with(param1="value1", additional_arg="value")
        mock_tracer.start_as_current_span.assert_called_once()

    @patch("orchestrator.experiment_wrapper.tracer")
    def test_run_exception(self, mock_tracer: MagicMock) -> None:
        self.mock_experiment.side_effect = Exception("Test exception")
        result = self.wrapper.run(data_filename="test_data.jsonl", line_number=5, call_args={"param1": "value1"})

        self.assertIn("error", result)
        self.assertEqual(result["error"], "Test exception")
        self.mock_experiment.assert_called_once_with(param1="value1", additional_arg="value")
        mock_tracer.start_as_current_span.assert_called_once()
