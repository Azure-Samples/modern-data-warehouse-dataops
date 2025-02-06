import re
from typing import Any

from rouge_score import rouge_scorer


def preprocess_text(text: str) -> str:
    # Remove special characters and extra spaces
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", "", text.lower()).strip())


def chunk_document(doc_id: str, document: str, chunk_size: int) -> list[dict[str, str]]:
    # Split the document into overlapping chunks
    words = document.split()
    return [{doc_id: " ".join(words[i : i + chunk_size])} for i in range(len(words) - chunk_size + 1)]


def similarity_ratio(citation: str, doc_chunk: str) -> float:
    """
    Calculates the ratio of similarity between the citation and the document
    chunk. Rouge-L metric is used here which measures the longest common
    subsequence (LCS) between the citation and retrieved document chunk.
    Recall measure is used here to capture how much of the citation is
    captured in the document chunk.
    """
    scorer = rouge_scorer.RougeScorer(["rougeL"], use_stemmer=True)
    # stemmer converts words into root form.
    # Eg: "programming", "programmer", "programs"
    # can be reduced down to "program"
    return scorer.score(citation, doc_chunk)["rougeL"].recall


def find_best_match(citation: list[str], document_chunks: list[dict[str, str]]) -> tuple[str, float, str]:
    """Finds the document chunk that has the closes
    match with the citation.
    """
    best_match, best_ratio, best_doc_id = "", 0.0, ""
    preprocessed_citation = preprocess_text(citation)
    for chunk in document_chunks:
        doc_id = list(chunk.keys())[0]
        chunk_text = list(chunk.values())[0]
        preprocess_chunk = preprocess_text(chunk_text)
        ratio = similarity_ratio(preprocessed_citation, preprocess_chunk)
        if ratio > best_ratio:
            best_ratio = ratio
            best_match = chunk_text
            best_doc_id = doc_id
    return best_match, best_ratio, best_doc_id


def map_citation_to_documents(
    citation: str, documents: dict[str, str], match_threshold: float = 0.5, buffer_size: int = 3
) -> dict[str, Any]:
    """
    Maps a given citation to the most relevant chunk of text within a
    collection of documents.

    Args:
        citation: The string to be matched.
        documents: A dictionary where keys are document IDs and values are
                   the corresponding document text.
        match_threshold: The minimum similarity score required for a chunk
                         to be considered a match. (Default: 0.5)
                         This value needs to be experimented with.
        buffer_size: The number of words to include as buffer for chunk size
                     to account for formatting differences etc. (Default: 3)
                     This value also needs to be experimented with.

    Returns:
        A dictionary with:
            doc_id: indicating the document ID containing matched text
            matched_text: text with best match to the citation
            match_ratio: similarity score between matched_text and citation
    """
    mapped_citation = {}
    best_ratio = 0.0

    # chunk the docs to the citation length
    window_size = len(citation.split())
    chunks = []
    for doc_id, document in documents.items():
        chunks.extend(chunk_document(doc_id, document, window_size + buffer_size))
    best_match, best_ratio, best_doc_id = find_best_match(citation, chunks)
    if best_ratio > match_threshold:
        mapped_citation = {"doc_id": best_doc_id, "matched_text": best_match, "match_ratio": best_ratio}
    return mapped_citation
