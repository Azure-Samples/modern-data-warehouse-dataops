from typing import Any

from azure.ai.evaluation import RougeScoreEvaluator, RougeType
from evaluators.citation_evaluator import CitationEvaluator


class FuzzyMatchCitationEvaluator(CitationEvaluator):
    """
    Calculates the ROUGE score for a given response and ground truth.
    Rouge-L metric is used here which measures the longest common
    subsequence (LCS) between the response and ground truth.
    """

    # TODO: what is a good default threshold for this?
    def __init__(self, match_threshold: float = 0.7, **kwargs: Any):
        super().__init__(
            evaluator=RougeScoreEvaluator(rouge_type=RougeType.ROUGE_L),
            score_key="rouge_recall",
            match_threshold=match_threshold,
            **kwargs,
        )
