import shutil
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Optional

from azure.ai.evaluation import EvaluationResult, evaluate
from orchestrator.evaluation_config import EvaluatorConfig
from orchestrator.store_results import MlflowType, store_results


@dataclass
class EvaluationWrapper:

    experiment_name: str
    variant_name: str
    version: str
    eval_run_id: str
    data_path: str
    experiment_run_id: str
    evaluators: dict[str, Callable]
    evaluator_config: dict[str, EvaluatorConfig]
    tags: dict = field(default_factory=dict)

    def run(
        self,
        evaluation_name: Optional[str] = None,
        output_path: Optional[Path] = None,
        mlflow_type: Optional[MlflowType] = None,
    ) -> EvaluationResult:
        """
        Evaluates the against a jsonl file and optionally uploads the results to Azure Machine Learning (AML) workspace.

        Args:
            evaluation_name (Optional[str]): The name of the evaluation. Defaults to None.
            output_path (Optional[Path]): The path to save the evaluation results. If not provided, a temporary
                directory will be used. Defaults to None.
            aml_workspace (Optional[AMLWorkspace]): The AML workspace to upload the results to. Defaults to None.

        Returns:
            EvaluationResult: The results of the evaluation.
        """
        tags = {
            "run_id": self.experiment_run_id,
            "variant.name": self.variant_name,
            "variant.version": self.version,
            "eval_run_id": self.eval_run_id,
        }
        tags.update(self.tags)

        try:
            # create temp dir if output path is not provided
            temp_dir = None
            if output_path is None:
                temp_dir = Path(tempfile.mkdtemp())
                output_path = temp_dir.joinpath("eval_data.json")

            # evaluate the results
            results = evaluate(
                evaluation_name=evaluation_name,
                data=self.data_path,
                evaluators=self.evaluators,
                evaluator_config=self.evaluator_config,
                output_path=str(output_path),
            )

            # upload to databricks
            if mlflow_type == MlflowType.DATABRICKS:
                store_results(
                    experiment_name=self.experiment_name,
                    job_name=self.variant_name,
                    tags=tags,
                    metrics=results["metrics"],
                    artifacts=[output_path],
                )

        # clean up temp dir
        finally:
            if temp_dir is not None:
                shutil.rmtree(temp_dir)

        return results
