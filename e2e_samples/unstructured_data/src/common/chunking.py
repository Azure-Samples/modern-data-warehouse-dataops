from dataclasses import dataclass

import tiktoken
from common.analyze_submissions import AnalyzedDocument


@dataclass
class DocumentChunks:
    chunks: list[str]
    document_name: str


def get_encoded_tokens(text: str, encoding_name: str) -> list[int]:
    """Get the tokens of a text

    Args:
        text (str): the text to get the token count of
        encoding_name (str): the encoding to use

    Returns:
        list[int]: the token count
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
    """
    Splits the input text into chunks of a specified word size.

    Args:
        text (str): The input text to be chunked.
        chunk_size (int): The number of words per chunk.

    Returns:
        list[str]: A list of text chunks, each containing the specified number of words.
    """
    words = text.split()
    return [" ".join(words[i : i + chunk_size]) for i in range(len(words) - chunk_size + 1)]


def chunk_by_token(encoding_name: str, text: str, max_tokens: int, overlap: int) -> list[str]:
    """
    Splits the input text into chunks based on the specified token encoding.

    Args:
        encoding_name (str): The name of the encoding to use for tokenization.
        text (str): The input text to be chunked.
        max_tokens (int): The maximum number of tokens per chunk.
        overlap (int): The number of tokens to overlap between consecutive chunks.

    Returns:
        list[str]: A list of text chunks, each containing up to `max_tokens` tokens.
    """
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


def get_context_max_tokens(text: str, encoding_name: str, max_tokens: int) -> int:
    prompt_tokens_without_context = get_encoded_tokens(text=text, encoding_name=encoding_name)
    max_context_tokens = max_tokens - len(prompt_tokens_without_context)
    if max_context_tokens <= 0:
        raise ValueError(f"Prompt is too long. Please reduce the prompt length to fit within {max_tokens} tokens.")
    return max_context_tokens


@dataclass
class AnalyzedDocChunker:
    """
    A class used to chunk analyzed documents by tokens.

    Attributes
    ----------
    max_tokens: (int) The maximum number of tokens allowed in each chunk.
    encoding_name: (str) The name of the encoding used for tokenization.
    overlap: (Optional[int]) The number of tokens to overlap between chunks (default is 0).

    Methods
    -------
    chunk_by_token(docs: list[AnalyzedDocument]) -> list[DocumentChunks]:
        Chunks the provided analyzed documents by tokens and returns a list of DocumentChunks.
    """

    max_tokens: int
    encoding_name: str
    overlap: int = 0

    def chunk_by_token(self, docs: list[AnalyzedDocument]) -> list[DocumentChunks]:
        """
        Splits a list of analyzed documents into chunks based on token count.

        Args:
            docs (list[AnalyzedDocument]): A list of analyzed documents to be chunked.

        Returns:
            list[DocumentChunks]: list of DocumentChunks, each containing the document name and its corresponding chunks
        """
        results = []
        for doc in docs:
            chunks = chunk_by_token(self.encoding_name, doc.di_result["content"], self.max_tokens, self.overlap)
            results.append(DocumentChunks(document_name=doc.document_name, chunks=chunks))
        return results
