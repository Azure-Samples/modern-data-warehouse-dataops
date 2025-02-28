import unittest
from unittest.mock import MagicMock, patch

from common.citation import Citation, InvalidCitation, MatchResult, ValidCitation
from common.citation_generator_utils import validate_citation


class TestValidateCitation(unittest.TestCase):

    @patch("common.citation_generator_utils.find_best_match")
    def test_validate_citation_valid(self, mock_find_best_match: MagicMock) -> None:
        excerpt = "test excerpt"
        doc_name = "test_doc.pdf"
        citation = Citation(document_name=doc_name, excerpt=excerpt)
        chunk = "This is a test chunk containing the test excerpt and some more text."

        mock_find_best_match.return_value = MatchResult(ratio=1.0, text=excerpt)

        result = validate_citation(citation, chunk)

        self.assertIsInstance(result, ValidCitation)
        self.assertEqual(result.excerpt, excerpt)
        self.assertEqual(result.document_name, doc_name)
        self.assertIsNotNone(result.match)
        if result.match is not None:
            self.assertEqual(result.match.ratio, 1.0)

    @patch("common.citation_generator_utils.find_best_match")
    def test_validate_citation_invalid_no_match(self, mock_find_best_match: MagicMock) -> None:
        excerpt = "test excerpt"
        doc_name = "test_doc.pdf"
        citation = Citation(document_name=doc_name, excerpt=excerpt)
        chunk = "This is a test chunk containing the test excerpt and some more text."

        mock_find_best_match.return_value = None

        result = validate_citation(citation, chunk)

        self.assertIsInstance(result, InvalidCitation)
        self.assertIsNone(result.match)
        self.assertEqual(result.excerpt, excerpt)
        self.assertEqual(result.document_name, doc_name)

    @patch("common.citation_generator_utils.find_best_match")
    def test_validate_citation_invalid_below_threshold(self, mock_find_best_match: MagicMock) -> None:
        excerpt = "test excerpt"
        doc_name = "test_doc.pdf"
        citation = Citation(document_name=doc_name, excerpt=excerpt)
        chunk = "This is a test chunk containing the test excerpt and some more text."

        mock_find_best_match.return_value = MatchResult(ratio=0.0, text=excerpt)

        result = validate_citation(citation, chunk)

        self.assertIsInstance(result, InvalidCitation)
        self.assertEqual(result.excerpt, excerpt)
        self.assertEqual(result.document_name, doc_name)
        self.assertIsNotNone(result.match)
        if result.match is not None:
            self.assertEqual(result.match.ratio, 0.0)

    def test_validate_citation_missing_excerpt(self) -> None:
        doc_name = "test_doc.pdf"
        citation = Citation(document_name=doc_name, excerpt=None)
        chunk = "This is a test chunk containing some more text."

        result = validate_citation(citation, chunk)

        self.assertIsInstance(result, InvalidCitation)
        if isinstance(result, InvalidCitation):
            self.assertEqual(result.error, "Missing 'excerpt' key")
