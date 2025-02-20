import shutil
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Optional

from azure.ai.evaluation import EvaluationResult, evaluate
from orchestrator.aml import AMLWorkspace, store_results
from orchestrator.evaluation_config import EvaluatorConfig


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

    def evaluate_experiment_result(
        self,
        evaluation_name: Optional[str] = None,
        output_path: Optional[Path] = None,
        aml_workspace: Optional[AMLWorkspace] = None,
    ) -> EvaluationResult:
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

            # upload to aml
            if aml_workspace:
                store_results(
                    experiment_name=self.experiment_name,
                    job_name=self.variant_name,
                    aml_workspace=aml_workspace,
                    tags=tags,
                    metrics=results["metrics"],
                    artifacts=[output_path],
                )

        # clean up temp dir
        finally:
            if temp_dir is not None:
                shutil.rmtree(temp_dir)

        return results
