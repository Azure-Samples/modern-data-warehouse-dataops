from dataclasses import dataclass

import tiktoken
from common.analyze_submissions import AnalyzedDocument


@dataclass
class DocumentChunks:
    chunks: list[str]
    document_name: str


def get_encoded_tokens(text: str, encoding_name: str) -> list[int]:
    """Get the token count of a text

    Args:
        text (str): the text to get the token count of
        encoding_name (str): the encoding to use

    Returns:
        int: the token count
    """
    encoding = tiktoken.get_encoding(encoding_name)
    return encoding.encode(text)


def decode_tokens(tokens: list[int], encoding_name: str) -> str:
    """Decode tokens back to text

    Args:
        tokens (list[int]): the tokens to decode
        encoding_name (str): the encoding to use

    Returns:
        str: the decoded text
    """
    encoding = tiktoken.get_encoding(encoding_name)
    return encoding.decode(tokens)


def chunk_by_word_size(text: str, chunk_size: int) -> list[str]:
    words = text.split()
    return [" ".join(words[i : i + chunk_size]) for i in range(len(words) - chunk_size + 1)]


def chunk_by_token(encoding_name: str, text: str, max_tokens: int, overlap: int) -> list[str]:
    tokens = get_encoded_tokens(text, encoding_name)
    chunks = []
    start = 0
    while start < len(tokens):
        end = start + max_tokens
        chunk_tokens = tokens[start:end]
        chunk_text = decode_tokens(chunk_tokens, encoding_name)
        chunks.append(chunk_text)
        start += max_tokens - overlap
    return chunks


def get_chunk_max_tokens(text: str, encoding_name: str, max_tokens: int, overlap: int) -> int:
    prompt_tokens_without_context = get_encoded_tokens(text=text, encoding_name=encoding_name)
    max_context_tokens = max_tokens - len(prompt_tokens_without_context)
    if max_context_tokens <= 0:
        raise ValueError(f"Prompt is too long. Please reduce the prompt length to fit within {max_tokens} tokens.")
    elif max_context_tokens < overlap:
        raise ValueError(
            f"Max context tokens {max_context_tokens} must be greater than overlap {overlap}.\
                Please reduce overlap or reduce the prompt length."
        )
    return max_context_tokens


@dataclass
class AnalyzedDocChunker:
    max_tokens: int
    encoding_name: str
    overlap: int = 0

    def chunk_by_token(self, docs: list[AnalyzedDocument]) -> list[DocumentChunks]:
        results = []
        for doc in docs:
            chunks = chunk_by_token(self.encoding_name, doc.di_result["content"], self.max_tokens, self.overlap)
            results.append(DocumentChunks(document_name=doc.document_name, chunks=chunks))
        return results
