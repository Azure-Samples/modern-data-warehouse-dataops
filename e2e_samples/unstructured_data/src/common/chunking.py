from dataclasses import dataclass

import tiktoken
from common.analyze_submissions import AnalyzedDocument


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


@dataclass
class DocumentChunks:
    chunks: list[str]
    doc: AnalyzedDocument


@dataclass
class DocContentChunker:
    max_tokens: int
    encoding_name: str
    overlap: int = 0

    def chunk(self, docs: list[AnalyzedDocument]) -> list[DocumentChunks]:
        results = []
        for doc in docs:
            text = ""
            for p in doc.di_result["pages"]:
                for w in p["words"]:
                    text += w["content"] + " "

            tokens = get_encoded_tokens(text, self.encoding_name)
            # tokens = get_encoded_tokens(doc.di_result["content"], self.encoding_name)
            chunks = []
            start = 0
            while start < len(tokens):
                end = start + self.max_tokens
                chunk_tokens = tokens[start:end]
                chunk_text = decode_tokens(chunk_tokens, self.encoding_name)
                chunks.append(chunk_text)
                start += self.max_tokens - self.overlap
            results.append(DocumentChunks(doc=doc, chunks=chunks))
        return results
