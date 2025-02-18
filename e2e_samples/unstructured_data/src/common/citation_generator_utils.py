from dataclasses import asdict

from common.chunking import chunk_by_word_size
from common.citation import Citation, InvalidCitation, ValidCitation
from common.fuzzy_matching import find_best_match


def validate_citation(
    citation: Citation,
    chunk: str,
    match_threshold: float = 0.5,
    buffer_size: int = 3,
) -> Citation | InvalidCitation:
    """Validates retrieved citations and return invalid or valid citations

    Args:
        retrieved_citations (Any): The citations to validate
        docs (list[AnalyzedDocument]): the list of docs to validate the
            citation exerpts are in the document text

    Returns:
        list[ValidCitation | Invalidcitation]: a list of valid or invalid citations
    """
    citation_dict = asdict(citation)
    if citation.excerpt is None:
        return InvalidCitation(
            error="Missing 'excerpt' key",
            **citation_dict,
        )

    window_size = len(citation.excerpt.split())
    word_chunks = chunk_by_word_size(chunk, window_size + buffer_size)

    match = find_best_match(citation.excerpt, word_chunks)

    if not match:
        error_msg = "No match found"
    elif match.ratio > match_threshold:
        return ValidCitation(
            match=match,
            **citation_dict,
        )
    else:
        error_msg = f"No match found above threshold {match_threshold}, Best ratio: {match.ratio}"

    return InvalidCitation(
        match=match,
        error=error_msg,
        **citation_dict,
    )
