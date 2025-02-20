import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from orchestrator.aml import AMLWorkspace
from orchestrator.evaluation_config import EvaluatorConfig
from orchestrator.evaluation_wrapper import EvaluationWrapper


class TestEvaluationWrapper(unittest.TestCase):

    @patch("orchestrator.evaluation_wrapper.evaluate")
    @patch("orchestrator.evaluation_wrapper.store_results")
    @patch("tempfile.mkdtemp")
    @patch("shutil.rmtree")
    def test_evaluate_experiment_result(
        self, mock_rmtree: MagicMock, mock_mkdtemp: MagicMock, mock_store_results: MagicMock, mock_evaluate: MagicMock
    ) -> None:
        # Setup
        mock_mkdtemp.return_value = "/tmp/testdir"
        mock_evaluate.return_value = {"metrics": {"accuracy": 0.95}}
        mock_aml_workspace = MagicMock(spec=AMLWorkspace)
        evaluator_config = EvaluatorConfig()
        evaluators = {"evaluator1": MagicMock()}

        wrapper = EvaluationWrapper(
            experiment_name="test_experiment",
            variant_name="test_variant",
            version="test_version",
            eval_run_id="test_eval_run_id",
            data_path="test_data_path",
            experiment_run_id="test_experiment_run_id",
            evaluators=evaluators,
            evaluator_config=evaluator_config,
            tags={"custom_tag": "value"},
        )

        # Test without output_path and aml_workspace
        results = wrapper.evaluate_experiment_result(evaluation_name="test_evaluation")
        self.assertEqual(results, {"metrics": {"accuracy": 0.95}})
        mock_evaluate.assert_called_once_with(
            evaluation_name="test_evaluation",
            data="test_data_path",
            evaluators=evaluators,
            evaluator_config=evaluator_config,
            output_path=str(Path("/tmp/testdir/eval_data.json")),
        )
        mock_rmtree.assert_called_once_with(Path("/tmp/testdir"))

        # Test with output_path and aml_workspace
        output_path = Path("/tmp/output.json")
        results = wrapper.evaluate_experiment_result(
            evaluation_name="test_evaluation",
            output_path=output_path,
            aml_workspace=mock_aml_workspace,
        )
        self.assertEqual(results, {"metrics": {"accuracy": 0.95}})
        mock_evaluate.assert_called_with(
            evaluation_name="test_evaluation",
            data="test_data_path",
            evaluators=evaluators,
            evaluator_config=evaluator_config,
            output_path=str(output_path),
        )
        mock_store_results.assert_called_once_with(
            experiment_name="test_experiment",
            job_name="test_variant",
            aml_workspace=mock_aml_workspace,
            tags={
                "run_id": "test_experiment_run_id",
                "variant.version": "test_version",
                "variant.name": "test_variant",
                "eval_run_id": "test_eval_run_id",
                "custom_tag": "value",
            },
            metrics={"accuracy": 0.95},
            artifacts=[output_path],
        )
