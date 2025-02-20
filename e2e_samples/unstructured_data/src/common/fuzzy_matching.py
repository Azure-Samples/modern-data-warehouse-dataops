import re

from common.citation import MatchResult
from rouge_score import rouge_scorer


def preprocess_text(text: str) -> str:
    # Remove special characters and extra spaces
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", "", text.lower()).strip())


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


def find_best_match(citation: str, chunks: list[str]) -> MatchResult | None:
    """Finds the document chunk that has the closes
    match with the citation.
    """
    best_match, best_ratio = "", 0.0
    preprocessed_citation = preprocess_text(citation)
    for chunk in chunks:
        preprocess_chunk = preprocess_text(chunk)
        ratio = similarity_ratio(preprocessed_citation, preprocess_chunk)
        if ratio > best_ratio:
            best_ratio = ratio
            best_match = chunk
            if best_ratio == 1.0:
                break
    return MatchResult(text=best_match, ratio=best_ratio)
