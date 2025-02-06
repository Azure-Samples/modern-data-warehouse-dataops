from typing import Any

from azure.ai.evaluation import RougeScoreEvaluator, RougeType
from evaluators.types import EvalResult


class FuzzyMatchEvaluator:
    """
    Calculates the ROUGE score for a given response and ground truth.
    Rouge-L metric is used here which measures the longest common
    subsequence (LCS) between the response and ground truth.
    """

    def __init__(self, **kwargs: Any):
        self.evaluator = RougeScoreEvaluator(rouge_type=RougeType.ROUGE_L)

    def __call__(self, response: list, truth: str, **kwargs: Any) -> EvalResult:
        if not truth:
            if response:
                # we have responses, but truth says we should not have any
                return EvalResult(ratio=0.0)
            else:
                # If truth is none and no citations. The generator did well
                return EvalResult(ratio=1.0)
        elif not response:
            # we have truth but no citations
            return EvalResult(ratio=0.0)

        scores = []
        for r in response:
            excerpt = r.get("excerpt")
            if excerpt is None:
                scores.append(0.0)
            else:
                score_dict = self.evaluator(response=excerpt, ground_truth=truth)
                scores.append(score_dict["rouge_recall"])

        return EvalResult(ratio=sum(scores) / len(scores))
