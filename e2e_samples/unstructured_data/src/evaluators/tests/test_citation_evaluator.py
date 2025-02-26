import unittest
from unittest.mock import MagicMock

from src.evaluators.citation_evaluator import CitationEvaluator


class MockCitationEvaluator(CitationEvaluator):
    def evaluate(self, ground_truth: str, response: str) -> float:
        return 0.0  # Dummy implementation


class TestCitationEvaluator(unittest.TestCase):

    def setUp(self) -> None:
        self.mock_citation_evaluator = MockCitationEvaluator(match_threshold=0.7)
        self.mock_citation_evaluator.evaluate = MagicMock()  # type: ignore

    def test_evaluate_any_all_match(self) -> None:
        citations = [
            {"excerpt": "excerpt-1", "document_name": "doc1"},
            {"excerpt": "excerpt-2", "document_name": "doc1"},
        ]
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [0.7, 0.0, 0.0, 1.0]  # type: ignore

        result = self.mock_citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 1.0)

    def test_evaluate_any_no_match(self) -> None:
        citations = [
            {"excerpt": "no_match", "document_name": "doc1"},
            {"excerpt": "no_match", "document_name": "doc1"},
        ]
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [  # type: ignore
            0.1,
            0.2,
            0.3,
            0.4,
        ]

        result = self.mock_citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_evaluate_any_some_match(self) -> None:
        citations = [
            {"excerpt": "excerpt-1", "document_name": "doc1"},
            {"excerpt": "no_match", "document_name": "doc1"},
        ]
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [  # type: ignore
            0.8,
            0.0,
            0.0,
            0.0,
        ]

        result = self.mock_citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.5)

    def test_evaluate_any_empty_citations(self) -> None:
        citations: list = []
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        result = self.mock_citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_evaluate_any_no_excerpt(self) -> None:
        citations: list = [{}]
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        result = self.mock_citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_get_best_truth_score_no_match(self) -> None:
        citation = {"excerpt": "excerpt-1", "document_name": "doc1"}
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [0.6, 0.5]  # type: ignore

        result = self.mock_citation_evaluator.get_best_truth_score(truth, citation)

        self.assertEqual(result.truth_idx, 0)
        self.assertEqual(result.score, 0.6)

    def test_get_best_truth_score_single_match(self) -> None:
        citation = {"excerpt": "excerpt-1", "document_name": "doc1"}
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [0.8, 0.5]  # type: ignore

        result = self.mock_citation_evaluator.get_best_truth_score(truth, citation)

        self.assertEqual(result.truth_idx, 0)

    def test_get_best_truth_score_multiple_matches(self) -> None:
        citation = {"excerpt": "excerpt-1", "document_name": "doc1"}
        truth = [{"excerpt": "excerpt-1", "document": "doc1"}, {"excerpt": "excerpt-2", "document": "doc1"}]

        self.mock_citation_evaluator.evaluate.side_effect = [0.8, 0.9]  # type: ignore

        result = self.mock_citation_evaluator.get_best_truth_score(truth, citation)

        self.assertEqual(result.truth_idx, 1)
