from common.analyze_submissions import AnalyzedDocument
from common.citation import Citation, InvalidCitation, ValidCitation
from common.fuzzy_matching import find_best_match


def validate_citation(
    citation: Citation,
    chunk: str,
    doc: AnalyzedDocument,
    match_threshold: float = 0.5,
) -> ValidCitation | InvalidCitation:
    """
    Maps a citation to a chunk of text within an analyzed document.

    Args:
        citation (Citation): The citation object containing the excerpt to be matched.
        chunk (str): The chunk of text to search within.
        doc (AnalyzedDocument): The analyzed document containing the text to be searched.
        match_threshold (float, optional): The threshold for considering a match valid. Defaults to 0.5.

    Returns:
        ValidCitation: If a valid match is found, returns a ValidCitation object containing details of the match.
        InvalidCitation: If no valid match is found, returns an InvalidCitation object with an error message.
    """
    if citation.excerpt is None:
        return InvalidCitation(
            citation=citation,
            error="Missing 'excerpt' key",
        )

    # chunk the docs to the citation length
    window_size = len(citation.excerpt.split())

    chunk_chars = chunk.split()
    chunks = [" ".join(chunk_chars[i : i + window_size]) for i in range(len(chunk_chars) - window_size + 1)]

    best_match, best_ratio = find_best_match(citation.excerpt, chunks)

    if best_ratio > match_threshold:

        prev_page_words = ""
        for i, p in enumerate(doc.di_result["pages"]):
            page_words = " ".join([w["content"] for w in p["words"]])

            start_char_idx = page_words.find(best_match)
            if prev_page_words:
                combined_page_words = f"{prev_page_words} {page_words}"
            else:
                combined_page_words = page_words

            match_from_prev_page = False
            if start_char_idx == -1 and prev_page_words:
                start_char_idx = combined_page_words.find(best_match)
                match_from_prev_page = True

            # if citation is found
            if start_char_idx != -1:
                # word_start_idx = len(combined_page_words[:start_char_idx].split())
                match_word_len = len(best_match.split())

                if match_from_prev_page:
                    word_start_idx = len(combined_page_words[:start_char_idx].split())
                    start_page = p["page_number"] - 1
                    di_word_start = doc.di_result["pages"][i - 1]["words"][word_start_idx]
                    prev_page_word_length = len(doc.di_result["pages"][i - 1]["words"])
                    word_end_idx = start_char_idx - prev_page_word_length + match_word_len
                    di_word_end = doc.di_result["pages"][i - 1]["words"][word_end_idx]
                else:
                    word_start_idx = len(page_words[:start_char_idx].split())
                    start_page = p["page_number"]
                    di_word_start = doc.di_result["pages"][i]["words"][word_start_idx]
                    word_end_idx = word_start_idx + match_word_len - 1
                    di_word_end = doc.di_result["pages"][i]["words"][word_end_idx]

                return ValidCitation(
                    citation=citation,
                    best_match=best_match,
                    start_page=start_page,
                    end_page=p["page_number"],
                    di_word_start=di_word_start,
                    di_word_end=di_word_end,
                    match_ratio=best_ratio,
                )
            # elif prev_page_words:
            #     prev_page_words = ""
            else:
                prev_page_words = page_words

    return InvalidCitation(
        citation=citation,
        error="Citation not found",
    )
