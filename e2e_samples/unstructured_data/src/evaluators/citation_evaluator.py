from dataclasses import dataclass
from typing import Optional, Protocol


class EvaluatorProtocol(Protocol):
    def __call__(self, *, response: str, ground_truth: str) -> float | dict[str, float]: ...


@dataclass
class Score:
    score: float
    truth_idx: Optional[int] = None


@dataclass
class CitationEvaluator:
    evaluator: EvaluatorProtocol
    match_threshold: float
    score_key: Optional[str] = None

    def __call__(self, truth: list, response: list, expected_match: Optional[str] = None):  # type: ignore
        if expected_match is None or expected_match == "any":
            # calculate precision for any.
            # this is the num of citations that have a truth match divided by the total number of generated citations
            # citation is a good match if it matches any truth above the match threshold
            return self.evaluate_any(truth, response)
        raise ValueError(f"Unknown expected match: {expected_match}")

    def get_best_truth_score(self, truth: list[dict], citation: dict) -> Score:
        excerpt = citation.get("excerpt")
        if excerpt is None:
            return Score(score=0.0)

        best_score = 0.0
        best_score_truth_idx = None

        for i, t in enumerate(truth):
            truth_excerpt = t.get("excerpt")
            if truth_excerpt is None:
                raise ValueError("truth excerpt must be set")
            truth_doc = t.get("document")
            citation_doc = citation.get("document_name")
            if citation_doc == truth_doc:
                score = self.evaluator(ground_truth=truth_excerpt, response=excerpt)

                if isinstance(score, dict):
                    if self.score_key is None:
                        raise ValueError("score_key must be set when evaluator returns a dict")
                    score = score[self.score_key]

                if score > best_score:
                    best_score_truth_idx = i
                    best_score = score

        return Score(score=best_score, truth_idx=best_score_truth_idx)

    def evaluate_any(self, truth: list, citations: list) -> dict[str, float]:
        # Num of matching citations to ground truth
        true_positives = 0

        # For each citation, determine if it matches any ground truth citation
        for citation in citations:
            score = self.get_best_truth_score(truth=truth, citation=citation)
            if score.truth_idx is not None and score.score >= self.match_threshold:
                true_positives += 1

        # number of true citations out of all the generated citations
        precision = true_positives / len(citations) if len(citations) > 0 else 0.0

        return {
            "precision": precision,
        }
