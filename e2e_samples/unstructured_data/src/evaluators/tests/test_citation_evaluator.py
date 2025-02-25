import unittest
from unittest.mock import Mock

from src.evaluators.citation_evaluator import CitationEvaluator, EvaluatorProtocol


class TestCitationEvaluator(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_evaluator = Mock(spec=EvaluatorProtocol)
        self.citation_evaluator = CitationEvaluator(
            evaluator=self.mock_evaluator, score_key="score", match_threshold=0.7
        )

    def test_evaluate_any_all_match(self) -> None:
        citations = [{"excerpt": "citation1"}, {"excerpt": "citation2"}]
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.7}, {"score": 0.8}, {"score": 0.9}, {"score": 1.0}]

        result = self.citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 1.0)

    def test_evaluate_any_no_match(self) -> None:
        citations = [{"excerpt": "citation1"}, {"excerpt": "citation2"}]
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.1}, {"score": 0.2}, {"score": 0.3}, {"score": 0.4}]

        result = self.citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_evaluate_any_some_match(self) -> None:
        citations = [{"excerpt": "citation1"}, {"excerpt": "citation2"}]
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.8}, {"score": 0.5}, {"score": 0.5}, {"score": 0.5}]

        result = self.citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.5)

    def test_evaluate_any_empty_citations(self) -> None:
        citations: list = []
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        result = self.citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_evaluate_any_no_excerpt(self) -> None:
        citations: list = [{}]
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        result = self.citation_evaluator.evaluate_any(truth, citations)

        self.assertEqual(result["precision"], 0.0)

    def test_get_best_truth_score_no_match(self) -> None:
        excerpt = "excerpt1"
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.6}, {"score": 0.5}]

        result = self.citation_evaluator.get_best_truth_score(truth, excerpt)

        self.assertIsNone(result.truth_idx)
        self.assertEqual(result.score, 0.0)

    def test_get_best_truth_score_single_match(self) -> None:
        excerpt = "excerpt1"
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.8}, {"score": 0.5}]

        result = self.citation_evaluator.get_best_truth_score(truth, excerpt)

        self.assertEqual(result.truth_idx, 0)

    def test_get_best_truth_score_multiple_matches(self) -> None:
        excerpt = "excerpt1"
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.mock_evaluator.side_effect = [{"score": 0.8}, {"score": 0.9}]

        result = self.citation_evaluator.get_best_truth_score(truth, excerpt)

        self.assertEqual(result.truth_idx, 1)

    def test_get_best_truth_score_score_key_not_set(self) -> None:
        excerpt = "excerpt1"
        truth = {"citations": ["truth1", "truth2"], "expected_match": "any"}

        self.citation_evaluator.score_key = None
        self.mock_evaluator.side_effect = [{"score": 0.8}, {"score": 0.9}]

        with self.assertRaises(ValueError):
            self.citation_evaluator.get_best_truth_score(truth, excerpt)
