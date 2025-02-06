import unittest

from common.analyze_submissions import AnalyzedDocument
from common.citation_generator_utils import Citation, InvalidCitation, validate_retrieved_citations


class TestCitationGeneratorUtils(unittest.TestCase):

    def test_validate_retrieved_citations_valid_citations(self) -> None:
        docs = [
            AnalyzedDocument(
                document_name="test",
                doc_url="",
                di_url="",
                di_result={"content": "this is some sample content to test"},
            )
        ]
        retrieved_citations = [{"excerpt": "content to test", "explanation": "test explanation"}]
        citations = validate_retrieved_citations(retrieved_citations=retrieved_citations, docs=docs)
        self.assertEqual(len(citations), 1)
        self.assertIsInstance(citations[0], Citation)
        self.assertEqual(citations[0].document_name, "test")
        # buffer size increases the citation length
        self.assertEqual(citations[0].excerpt, "is some sample content to test")
        self.assertEqual(citations[0].explanation, "test explanation")

    def test_validate_retrieved_citations_valid_citation_when_retrieved_not_list(  # noqa: E501
        self,
    ) -> None:
        docs = [
            AnalyzedDocument(
                document_name="test",
                doc_url="",
                di_url="",
                di_result={"content": "this is some sample content to test"},
            )
        ]
        retrieved_citations = {"excerpt": "content to test"}
        citations = validate_retrieved_citations(retrieved_citations=retrieved_citations, docs=docs)
        self.assertEqual(len(citations), 1)
        self.assertIsInstance(citations[0], Citation)
        self.assertEqual(citations[0].document_name, "test")
        self.assertEqual(citations[0].excerpt, "is some sample content to test")

    def test_validate_retrieved_citations_invalid_citation_missing_keys(self) -> None:
        docs = [
            AnalyzedDocument(
                document_name="test",
                doc_url="",
                di_url="",
                di_result={"content": "is some sample content to test"},
            )
        ]
        retrieved_citations = [{"explanation": "some explanation"}]
        citations = validate_retrieved_citations(retrieved_citations=retrieved_citations, docs=docs)

        self.assertEqual(len(citations), 1)

        self.assertIsInstance(citations[0], InvalidCitation)
        if isinstance(citations[0], InvalidCitation):
            self.assertEqual(
                citations[0].error,
                "Missing 'excerpt' key",
            )
        self.assertEqual(citations[0].excerpt, None)

    def test_validate_retrieved_citations_invalid_citation_excerpt_not_match(
        self,
    ) -> None:
        docs = [
            AnalyzedDocument(
                document_name="test",
                doc_url="",
                di_url="",
                di_result={"content": "is some sample content to test"},
            )
        ]
        retrieved_citations = [
            {"explanation": "some explanation", "excerpt": "not in document"},
        ]
        citations = validate_retrieved_citations(retrieved_citations=retrieved_citations, docs=docs)

        self.assertEqual(len(citations), 1)
        self.assertIsInstance(citations[0], InvalidCitation)
        if isinstance(citations[0], InvalidCitation):
            self.assertEqual(citations[0].error, "Excerpt is not an exact match is the document")
        self.assertEqual(citations[0].excerpt, retrieved_citations[0]["excerpt"])
        self.assertEqual(citations[0].explanation, retrieved_citations[0]["explanation"])
