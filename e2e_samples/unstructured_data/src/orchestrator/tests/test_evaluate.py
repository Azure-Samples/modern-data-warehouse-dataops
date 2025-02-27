import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from orchestrator.evaluate import (
    EvaluationResults,
    evaluate_experiment_results_by_run_id,
    evaluate_experiment_results_from_metadata,
)
from orchestrator.metadata import ExperimentMetadata
from orchestrator.store_results import MlflowType


class TestEvaluateExperimentResultsFromMetadata(unittest.TestCase):

    @patch("orchestrator.evaluate.new_run_id", return_value="test_run_id")
    @patch("orchestrator.evaluate.load_evaluation")
    def test_evaluate_experiment_results_from_metadata(
        self, mock_load_evaluation: MagicMock, mock_new_run_id: MagicMock
    ) -> None:
        # Setup
        metadata_paths = [Path("/path/to/metadata1"), Path("/path/to/metadata2")]
        mock_evaluation = MagicMock()
        mock_evaluation.run.return_value = "result"
        mock_load_evaluation.return_value = mock_evaluation

        # Execute
        results = evaluate_experiment_results_from_metadata(metadata_paths)

        # Verify
        self.assertEqual(results.eval_run_id, "test_run_id")
        self.assertEqual(results.results, ["result", "result"])
        mock_load_evaluation.assert_any_call(metadata_path=metadata_paths[0], eval_run_id="test_run_id")
        mock_load_evaluation.assert_any_call(metadata_path=metadata_paths[1], eval_run_id="test_run_id")
        mock_evaluation.run.assert_any_call(mlflow_type=None, output_path=None)

    @patch("orchestrator.evaluate.new_run_id", return_value="test_run_id")
    @patch("orchestrator.evaluate.load_evaluation")
    def test_evaluate_experiment_results_from_metadata_with_write_to_file(
        self, mock_load_evaluation: MagicMock, mock_new_run_id: MagicMock
    ) -> None:
        # Setup
        metadata_paths = [Path("/path/to/metadata1"), Path("/path/to/metadata2")]
        mock_evaluation = MagicMock()
        mock_evaluation.run.return_value = "result"
        mock_load_evaluation.return_value = mock_evaluation

        # Execute
        results = evaluate_experiment_results_from_metadata(metadata_paths, write_to_file=True)

        # Verify
        self.assertEqual(results.eval_run_id, "test_run_id")
        self.assertEqual(results.results, ["result", "result"])
        mock_load_evaluation.assert_any_call(metadata_path=metadata_paths[0], eval_run_id="test_run_id")
        mock_load_evaluation.assert_any_call(metadata_path=metadata_paths[1], eval_run_id="test_run_id")
        expected_output_path_1 = metadata_paths[0].parent.joinpath(
            f"test_run_id{ExperimentMetadata.eval_results_filename_suffix}"
        )
        expected_output_path_2 = metadata_paths[1].parent.joinpath(
            f"test_run_id{ExperimentMetadata.eval_results_filename_suffix}"
        )
        mock_evaluation.run.assert_any_call(mlflow_type=None, output_path=expected_output_path_1)
        mock_evaluation.run.assert_any_call(mlflow_type=None, output_path=expected_output_path_2)

    @patch("orchestrator.evaluate.get_output_dirs_by_run_id")
    @patch("orchestrator.evaluate.evaluate_experiment_results_from_metadata")
    def test_evaluate_experiment_results_by_run_id(
        self,
        mock_evaluate_experiment_results_from_metadata: MagicMock,
        mock_get_output_dirs_by_run_id: MagicMock,
    ) -> None:
        # Setup
        run_id = "test_run_id"
        dirs = [Path("/path/to/dir1"), Path("/path/to/dir2")]
        mock_get_output_dirs_by_run_id.return_value = dirs
        expected_metadata_paths = [d.joinpath(ExperimentMetadata.filename) for d in dirs]
        mock_evaluation_results = EvaluationResults(results=["result1", "result2"], eval_run_id="test_eval_run_id")
        mock_evaluate_experiment_results_from_metadata.return_value = mock_evaluation_results

        # Execute
        results = evaluate_experiment_results_by_run_id(run_id)

        # Verify
        self.assertEqual(results, mock_evaluation_results)
        mock_get_output_dirs_by_run_id.assert_called_once_with(run_id=run_id)
        mock_evaluate_experiment_results_from_metadata.assert_called_once_with(
            metadata_paths=expected_metadata_paths,
            mlflow_type=None,
            write_to_file=False,
        )

    @patch("orchestrator.evaluate.get_output_dirs_by_run_id")
    @patch("orchestrator.evaluate.evaluate_experiment_results_from_metadata")
    def test_evaluate_experiment_results_by_run_id_with_aml_workspace(
        self,
        mock_evaluate_experiment_results_from_metadata: MagicMock,
        mock_get_output_dirs_by_run_id: MagicMock,
    ) -> None:
        # Setup
        run_id = "test_run_id"
        dirs = [Path("/path/to/dir1"), Path("/path/to/dir2")]
        mock_get_output_dirs_by_run_id.return_value = dirs
        expected_metadata_paths = [d.joinpath(ExperimentMetadata.filename) for d in dirs]
        mock_evaluation_results = EvaluationResults(results=["result1", "result2"], eval_run_id="test_eval_run_id")
        mock_evaluate_experiment_results_from_metadata.return_value = mock_evaluation_results

        # Execute
        results = evaluate_experiment_results_by_run_id(run_id, mlflow_type=MlflowType.DATABRICKS)

        # Verify
        self.assertEqual(results, mock_evaluation_results)
        mock_get_output_dirs_by_run_id.assert_called_once_with(run_id=run_id)
        mock_evaluate_experiment_results_from_metadata.assert_called_once_with(
            metadata_paths=expected_metadata_paths,
            mlflow_type=MlflowType.DATABRICKS,
            write_to_file=False,
        )

    @patch("orchestrator.evaluate.get_output_dirs_by_run_id")
    @patch("orchestrator.evaluate.evaluate_experiment_results_from_metadata")
    def test_evaluate_experiment_results_by_run_id_with_write_to_file(
        self,
        mock_evaluate_experiment_results_from_metadata: MagicMock,
        mock_get_output_dirs_by_run_id: MagicMock,
    ) -> None:
        # Setup
        run_id = "test_run_id"
        dirs = [Path("/path/to/dir1"), Path("/path/to/dir2")]
        mock_get_output_dirs_by_run_id.return_value = dirs
        expected_metadata_paths = [d.joinpath(ExperimentMetadata.filename) for d in dirs]
        mock_evaluation_results = EvaluationResults(results=["result1", "result2"], eval_run_id="test_eval_run_id")
        mock_evaluate_experiment_results_from_metadata.return_value = mock_evaluation_results

        # Execute
        results = evaluate_experiment_results_by_run_id(run_id, write_to_file=True)

        # Verify
        self.assertEqual(results, mock_evaluation_results)
        mock_get_output_dirs_by_run_id.assert_called_once_with(run_id=run_id)
        mock_evaluate_experiment_results_from_metadata.assert_called_once_with(
            metadata_paths=expected_metadata_paths,
            mlflow_type=None,
            write_to_file=True,
        )
