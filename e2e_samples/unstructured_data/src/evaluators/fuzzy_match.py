from dataclasses import dataclass

from azure.ai.evaluation import RougeScoreEvaluator, RougeType
from evaluators.citation_evaluator import CitationEvaluator


@dataclass
class FuzzyMatchCitationEvaluator(CitationEvaluator):
    """
    Calculates the ROUGE score for a given response and ground truth.
    Rouge-L metric is used here which measures the longest common
    subsequence (LCS) between the response and ground truth.
    """

    score_key: str = "rouge_recall"
    evaluator: RougeScoreEvaluator = RougeScoreEvaluator(rouge_type=RougeType.ROUGE_L)

    def __init__(
        self,
        match_threshold: float = 0.7,
        rouge_type: RougeType = RougeType.ROUGE_L,
        score_key: str = "rouge_recall",
    ):
        self.evaluator = RougeScoreEvaluator(rouge_type=rouge_type)
        self.score_key = score_key
        super().__init__(match_threshold=match_threshold)

    def evaluate(self, ground_truth: str, response: str) -> float:
        score = self.evaluator(ground_truth=ground_truth, response=response)
        return score[self.score_key]
