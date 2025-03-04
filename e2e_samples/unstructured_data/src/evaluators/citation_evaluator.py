import logging
import math
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class Score:
    """
    A class to represent a score with an optional index for the ground truth.

    Attributes:
    ----------
    score : float - The score value.
    truth_idx : Optional[int], optional - The index of the ground truth, by default None.
    """

    score: float
    truth_idx: Optional[int] = None


@dataclass
class CitationEvaluator(ABC):
    """
    CitationEvaluator is an abstract base class for evaluating the accuracy of generated citations against ground truth
    citations.

    Attributes:
        match_threshold (float): The threshold above which a citation is considered a match with the ground truth.

    Methods:
        evaluate(ground_truth: str, response: str) -> float:
            Abstract method to evaluate the response against the ground truth.

        __call__(truth: list, response: list, expected_match: Optional[str] = None):
            Evaluate the response based on the expected match type.

        get_best_truth_score(truth: list[dict], citation: dict) -> Score:

        evaluate_any(truth: list, citations: list) -> float:
    """

    match_threshold: float

    @abstractmethod
    def evaluate(self, ground_truth: str, response: str) -> float:
        """
        Evaluate the response against the ground truth.

        Args:
            ground_truth (str): The correct reference or citation.
            response (str): The generated reference or citation to be evaluated.

        Returns:
            float: A score representing the accuracy of the response compared to the ground truth.
        """
        pass

    def __call__(self, truth: list, response: list, expected_match=None):  # type: ignore
        if expected_match is None or expected_match == "any" or math.isnan(expected_match):
            # calculate precision for any.
            # this is the num of citations that have a truth match divided by the total number of generated citations
            # citation is a good match if it matches any truth above the match threshold
            return self.evaluate_any(truth, response)
        raise ValueError(f"Unknown expected match: {expected_match}")

    def get_best_truth_score(self, truth: list[dict], citation: dict) -> Score:
        """
        Calculate the best score for a given citation against a list of ground truth excerpts.

        Args:
            truth (list[dict]): A list of dictionaries containing ground truth data. Each dictionary must have
                                an "excerpt" key with the text excerpt and a "document" key with the document name.
            citation (dict): A dictionary containing the citation data. It must have an "excerpt" key with the
                             text excerpt and a "document_name" key with the document name.

        Returns:
            Score: An instance of the Score class containing the best score and the index of the best matching
                   ground truth excerpt. If no matching document is found, the score is 0.0 and the index is None.

        """
        excerpt = citation.get("excerpt")
        if excerpt is None:
            return Score(score=0.0)

        best_score = 0.0
        best_score_truth_idx = None

        for i, t in enumerate(truth):
            truth_excerpt = t.get("excerpt")
            if truth_excerpt is None:
                logger.warning("truth excerpt must be set to enable evaluations")
                continue
            truth_doc = t.get("document")
            citation_doc = citation.get("document_name")
            if citation_doc == truth_doc:
                score = self.evaluate(ground_truth=truth_excerpt, response=excerpt)

                if score > best_score:
                    best_score_truth_idx = i
                    best_score = score

        return Score(score=best_score, truth_idx=best_score_truth_idx)

    def evaluate_any(self, truth: list, citations: list) -> float:
        """
        Evaluate the precision of generated citations against the ground truth.

        This method calculates the precision by determining the number of
        generated citations that match any of the ground truth citations.

        Args:
            truth (list): A list of ground truth citations.
            citations (list): A list of generated citations to be evaluated.

        Returns:
            float: The precision of the generated citations, which is the
                   number of true positives divided by the total number of
                   generated citations. If there are no generated citations,
                   the precision is 0.0.
        """
        # Num of matching citations to ground truth
        true_positives = 0

        # For each citation, determine if it matches any ground truth citation
        for citation in citations:
            score = self.get_best_truth_score(truth=truth, citation=citation)
            if score.truth_idx is not None and score.score >= self.match_threshold:
                true_positives += 1

        # number of true citations out of all the generated citations
        precision = true_positives / len(citations) if len(citations) > 0 else 0.0

        return precision
