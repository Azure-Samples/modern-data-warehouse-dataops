from dataclasses import dataclass, field
from typing import Any, Optional

from common.analyze_submissions import AnalyzedDocument
from common.fuzzy_matching import map_citation_to_documents


@dataclass
class Citation:
    excerpt: str
    document_name: str
    explanation: Optional[str] = field(default=None)
    status: str = "Valid"


@dataclass
class InvalidCitation:
    excerpt: Optional[str] = field(default=None)
    explanation: Optional[str] = field(default=None)
    document_name: Optional[str] = field(default=None)
    error: Optional[str] = field(default=None)
    status: str = "Invalid"


def validate_retrieved_citations(
    retrieved_citations: Any, docs: list[AnalyzedDocument]
) -> list[Citation | InvalidCitation]:
    """Validates retrieved citations and return invalid or valid citations

    Args:
        retrieved_citations (Any): The citations to validate
        docs (list[AnalyzedDocument]): the list of docs to validate the
            citation exerpts are in the document text

    Returns:
        list[ValidCitation | Invalidcitation]: a list of valid or invalid citations
    """
    if not isinstance(retrieved_citations, list):
        retrieved_citations = [retrieved_citations]

    citations: list[Citation | InvalidCitation] = []
    for c in retrieved_citations:
        citation = _validate_retrieved_citation(retrieved_citation=c, docs=docs)
        citations.extend(citation)
    return citations


def _validate_retrieved_citation(
    retrieved_citation: Any, docs: list[AnalyzedDocument]
) -> list[Citation | InvalidCitation]:
    results: list[Citation | InvalidCitation] = []
    if isinstance(retrieved_citation, dict):
        # ensure the dict has the required keys
        exerpt = retrieved_citation.get("excerpt")
        if exerpt is None:
            return [
                InvalidCitation(
                    error="Missing 'excerpt' key",
                    **retrieved_citation,
                )
            ]

        doc_map = {}
        for doc in docs:
            doc_map[doc.document_name] = doc.di_result["content"]

        # Fuzzy matching to grab actual text from document
        mapped_citation = map_citation_to_documents(exerpt, doc_map)
        print(
            f"[LOG] Original citation: {exerpt} \
              ***** Mapped citation: {mapped_citation}"
        )
        if mapped_citation:
            results.append(
                Citation(
                    document_name=str(mapped_citation["doc_id"]),
                    excerpt=str(mapped_citation["matched_text"]),
                    explanation=retrieved_citation.get("explanation"),
                )
            )
        # if no matches were found, its invalid
        else:
            results.append(
                InvalidCitation(
                    error="Excerpt is not an exact match is the document",
                    **retrieved_citation,
                )
            )
    return results
