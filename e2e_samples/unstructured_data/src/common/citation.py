from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Citation:
    document_name: str
    excerpt: Optional[str] = field(default=None)
    explanation: Optional[str] = field(default=None)
    raw: Optional[str] = field(default=None)


@dataclass
class ValidCitation:
    citation: Citation
    best_match: str
    start_page: Optional[int] = field(default=None)
    end_page: Optional[int] = field(default=None)
    di_word_start: Optional[dict] = field(default=None)
    di_word_end: Optional[dict] = field(default=None)
    match_ratio: Optional[float] = field(default=None)
    status: str = "Valid"


@dataclass
class InvalidCitation:
    citation: Citation
    error: Optional[str] = field(default=None)
    status: str = "Invalid"
