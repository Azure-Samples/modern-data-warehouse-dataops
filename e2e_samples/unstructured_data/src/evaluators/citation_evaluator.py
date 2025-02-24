from dataclasses import dataclass
from typing import Any, Optional, Protocol


class EvaluatorProtocol(Protocol):
    def __call__(self, *, response: str, ground_truth: str) -> Any: ...


@dataclass
class CitationEvaluator:
    evaluator: EvaluatorProtocol
    score_key: Optional[str] = None
    # TODO: what is a good default threshold?
    match_threshold: float = 0.7

    def __call__(self, response: list, truth: list, expected_match: Optional[str] = None):  # type: ignore
        expected_match = expected_match or "any"
        if expected_match == "any":
            # calculate precision for any,
            # this is the num of citations that have a truth match divided by the total number of generated citations
            # citation is a good match if it matches any truth
            return self.evaluate_any(response, truth)
        raise ValueError(f"Unknown expected match: {expected_match}")

    def get_truth_match_idx(self, citation: dict, truth: list[str]):  # type: ignore
        excerpt = citation.get("excerpt")
        if excerpt is None:
            return None
        best_match = 0.0
        best_match_idx = None
        for i, t in enumerate(truth):
            score = self.evaluator(response=excerpt, ground_truth=t)
            if isinstance(score, dict):
                if self.score_key is None:
                    raise ValueError("score_key must be set when evaluator returns a dict")
                score = score[self.score_key]
            if score >= self.match_threshold and score >= best_match:
                best_match_idx = i
                best_match = score
        return best_match_idx

    def evaluate_any(self, citations: list, truth: list):  # type: ignore
        # Num of matching citations to ground truth
        true_positives = 0
        # Num of citations that do not match any ground truth
        false_postives = 0

        # For each citation, determine if it matches any ground truth citation
        for citation in citations:
            truth_match_idx = self.get_truth_match_idx(citation, truth)
            if truth_match_idx is not None:
                true_positives += 1
            else:
                false_postives += 1

        # number of true citations out of all the generated citations
        precision = true_positives / len(citations) if len(citations) > 0 else 0

        return {
            "precision": precision,
        }
